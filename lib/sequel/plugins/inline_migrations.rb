#!/usr/bin/env ruby

require 'sequel'
require 'sequel/model'

Sequel.extension( :migration )


# A plugin for Sequel::Model that allows migrations for the model to be defined
# directly in the class declaration. It uses the `inline_schema` plugin
# internally, and will add it for you if necessary.
#
# ## Example
#
# Define a base (abstract) model class:
#
# ```
# # lib/acme/model.rb
# module Acme
#     Model = Class.new( Sequel::Model )
#     Model.def_Model( Acme )
#
#     class Model
#         plugin :inline_schema
#         plugin :inline_migrations
#     end
# end
# ```
#
# Defining a model class with two migrations:
#
# ```
# # lib/acme/vendor.rb
# require 'acme/model'
#
# class Acme::Vendor < Acme::Model( :vendor )
#
#     # The schema should always be kept up-to-date. I.e., it should be
#     # modified along with each migration to reflect the state of the table
#     # after the migration is applied.
#     set_schema do
#         primary_key :id
#         String :name
#         String :contact
#         timestamp :created_at, :null => false
#         timestamp :updated_at
#
#         add_index :name
#     end
#
#     # Similar to Sequel's TimeStampMigrator, inline migrations have a symbolic
#     # name, which is how they're tracked in the migrations table, and how
#     # they're ordered when they're applied. The second argument is a human-readable
#     # description that can be used for automated change control descriptions or
#     # other tooling.
#     migration( '20110228_1115_add_timestamps', "Add timestamp fields" ) do
#         change do
#             alter_table do
#                 add_column :created_at, :timestamp, :null => false
#                 add_column :updated_at, :timestamp
#             end
#             update( :created_at => :now[] )
#         end
#     end
#
#     migration( '20110303_1751_index_name', "Add an index to the name field" ) do
#         change do
#             alter_table do
#                 add_index :name
#             end
#         end
#     end
#
# end
# ```
#
# Apply pending migrations.
#
# ```
# # bin/migrate
#
# require 'acme/model'
# require 'acme/vendor'
# # ...
#
# puts "Creating new tables, applying any pending migrations..."
# Acme::Model.migrate
# ```
#
# ## Notable Model Methods
#
# See Sequel::Plugins::InlineSchema::ClassMethods for documentation for the methods the
# plugin adds to your model class/es.
#
# * `migration` -- define a migration
# * `migrate` -- create any missing tables for the receiving model and any subclasses,
#   then run any unapplied migrations.
#
# Inline migrations also have model hook methods:
#
# * `before_migration`
# * `after_migration`
#
# There's also a method that will return a configured Sequel::Plugins::InlineMigrations::Migrator
# in case you want to inspect what will happen when you call #migrate:
#
# * `migrator`
#
module Sequel::Plugins::InlineMigrations

	### Sequel plugin API -- Called the first time the plugin is loaded for
	### this model (unless it was already loaded by an ancestor class),
	### before including/extending any modules, with the arguments and block
	### provided to the call to Model.plugin.
	def self::apply( model, *args ) # :nodoc:
		@plugins ||= []
		model.plugin( :subclasses ) # track subclasses
		model.plugin( :inline_schema )
		model.instance_variable_set( :@migrations, {} )
	end


	### A mixin that gets applied to inline migrations to add introspection attributes
	### and accessors.
	module MigrationIntrospection

		### Extension callback -- adds 'name', 'model_class', and 'description' instance
		### variables.
		def self::extend_object( obj )
			super
			obj.instance_variable_set( :@description, nil )
			obj.instance_variable_set( :@model_class, nil )
			obj.instance_variable_set( :@name, nil )
		end

		attr_accessor :name, :model_class, :description

	end # module MigrationIntrospection


	# Methods to extend Model classes with.
	#
	# :markup: RDoc
	module ClassMethods

		# A Regexp for matching valid migration names
		MIGRATION_NAME_PATTERN = /\A\d{8}_\d{4}_\w+\z/


		# The Hash of Sequel::SimpleMigration objects for this model, keyed by name
		attr_reader :migrations


		### Add a migration with the specified +name+ and optional +description+. See the
		### docs for Sequel::Migration for usage, and Sequel::MigrationDSL for the allowed
		### syntax in the +block+. The name of the migration should be in the form:
		###   <year><month><day>_<hour><minute>_<underbarred_desc>
		def migration( name, description=nil, &block )
			raise ScriptError, "invalid migration name %p" % [ name ] unless
				MIGRATION_NAME_PATTERN.match( name )

			@migrations ||= {}
			migration_obj = Sequel::MigrationDSL.create( &block )
			migration_obj.extend( MigrationIntrospection )
			migration_obj.name = name
			migration_obj.model_class = self
			migration_obj.description = description

			@migrations[ name ] = migration_obj
		end


		### Table-migration hook; called once before missing tables are installed and pending
		### migrations are run.
		def before_migration
			return true
		end


		### Table-migration hook; called once after missing tables are installed and
		### pending migrations are run.
		def after_migration
			return true
		end


		### After table creation hook to register any existing migrations as being
		### already applied, as the schema declared by set_schema should be the *latest*
		### schema, and already incorporate the changes described by the migrations.
		def after_create_table
			super
			self.register_existing_migrations
		end


		### Register any migrations on the receiver as having already been run (as when creating
		### the table initially).
		def register_existing_migrations
			# Register existing migrations as already being applied
			if self.migrations && !self.migrations.empty?
				migrator = self.migrator

				self.migrations.each_value do |migration|
					migration_data = {
						name: migration.name,
						model_class: migration.model_class.name
					}
					next unless migrator.dataset.filter( migration_data ).empty?
					self.db.log_info "  fast-forwarding migration #{migration.name}..."
					migrator.dataset.insert( migration_data )
				end
			end
		end


		### Create any new tables and run any pending migrations. If the optional +target+ is
		### supplied, the migrations up to (and including) that one will be applied. If
		### it has already been applied, any from the currently-applied one to it
		### (inclusive) will be reversed. A target of +nil+ is equivalent to the last one
		def migrate( target=nil )
			migrator = self.migrator( target )
			classes_to_install = self.uninstalled_tables
			self.db.log_info "Classes with tables that need to be installed: %p" % [ classes_to_install ]
			views_to_install = self.installed_views + self.uninstalled_views
			self.db.log_info "Views to install: %p" % [ views_to_install.map(&:table_name) ]

			self.db.transaction do
				self.before_migration
				self.db.log_info "Creating tables that don't yet exist..."
				classes_to_install.each( &:create_table )

				self.db.log_info "Running any pending migrations..."
				migrator.run
				self.after_migration

				self.db.log_info "(Re)-creating any modeled views..."
				views_to_install.each( &:create_view! )
			end
		end


		### Return a configured inline migrator set with the given +target+ migration.
		def migrator( target=nil )
			self.db.log_info "Creating the migrator..."
			Sequel::Plugins::InlineMigrations::Migrator.new( self, nil, target: target )
		end


	end # module ClassMethods


	# Subclass of Sequel::Migrator that provides the logic for extracting and running
	# migrations from the model classes themselves.
	class Migrator < Sequel::Migrator

		# Default options for .run and #initialize.
		DEFAULT_OPTS = {
			:table  => :schema_migrations,
			:column => :name,
		}


		### Migrates the supplied +db+ (a Sequel::Database) using the migrations declared in the
		### given +baseclass+. The +baseclass+ is the class to gather migrations from; it and all
		### of its concrete descendents will be considered.
		###
		### The +options+ this method understands:
		###
		### column
		### : The column in the table that stores the migration version. Defaults to
		### `:version`.
		###
		### current
		### : The current version of the database.  If not given, it is retrieved from the
		### database using the `:table` and `:column` options.
		###
		### table
		### : The name of the migrations table. Defaults to `:schema_migrations`.
		###
		### target
		### : The target version to migrate to.  If not given, migrates to the
		### maximum version.
		###
		### Examples
		###
		### ```
		### # Assuming Acme::Model is a Sequel::Model subclass, and Acme::Vendor is a subclass
		### # of that...
		### Sequel::InlineMigrations::Migrator.run( Acme::Model )
		### Sequel::InlineMigrations::Migrator.run( Acme::Model, :target => 15, :current => 10 )
		### Sequel::InlineMigrations::Migrator.run( Acme::Vendor, :column => :app2_version)
		### Sequel::InlineMigrations::Migrator.run( Acme::Vendor, :column => :app2_version,
		###                                         :table => :schema_info2 )
		### ```
		def self::run( baseclass, db=nil, opts={} )
			if db.is_a?( Hash )
				opts = db
				db = nil
			end

			new( baseclass, db, opts ).run
		end


		### Create a new Migrator that will organize migrations defined for
		### +baseclass+ or any of its subclasses for the specified +db+.
		### See Sequel::Plugins::InlineMigrations::Migrator.run for argument details.
		def initialize( baseclass, db=nil, opts={} )
			if db.is_a?( Hash )
				opts = db
				db = nil
			end

			db ||= baseclass.db

			opts = DEFAULT_OPTS.merge( opts )
			schema, table = db.send( :schema_and_table, opts[:table] )

			@db        = db
			@baseclass = baseclass
			@table     = opts[ :table ]
			@column    = opts[ :column ]
			@target    = opts[ :target ]
			@dataset   = make_schema_dataset( @db, @table, @column )
		end


		######
		public
		######

		# The database to which the migrator will apply its migrations; a Sequel::Database.
		attr_reader :db

		# The Class at the top of the hierarchy from which migrations will be fetched
		attr_reader :baseclass

		# The name of the migration table as a Sequel::SQL::QualifiedIdentifier.
		attr_reader :table

		# The name of the column which will contain the names of applied migrations as a Symbol.
		attr_reader :column

		# The migration table dataset (a Sequel::Dataset).
		attr_reader :dataset

		# The name of the target migration to play up or down to as a String.
		attr_reader :target


		### Apply all migrations to the database
		def run
			applied, pending = self.get_partitioned_migrations

			# If no target was specified, and there are no pending
			# migrations, return early.
			return if pending.empty? && self.target.nil?

			# If no target was specified, the last one is the target
			target     = self.target || pending.last.name
			migrations = nil
			direction  = nil

			if target == '0'
				direction = :down
				migrations = applied.reverse

			elsif tgtidx = pending.find_index {|m| m.name == target }
				migrations = pending[ 0..tgtidx ]
				direction = :up

			elsif tgtidx = applied.find_index {|m| m.name == target }
				migrations = applied[ tgtidx..-1 ].reverse
				direction = :down

			else
				raise Sequel::Error, "couldn't find migration %p"
			end

			# Run the selected migrations
			self.db.log_info "Migrating %d steps %s..." % [ migrations.length, direction ]
			migrations.each do |migration|
				start = Time.now
				self.db.log_info "Begin: %s, direction: %s" %
					[ migration.description, direction ]

				self.db.transaction do
					migration.apply( self.db, direction )

					mclass = migration.model_class.name
					if direction == :up
						self.dataset.insert( self.column => migration.name, :model_class => mclass )
					else
						self.dataset.filter( self.column => migration.name, :model_class => mclass ).delete
					end
				end

				self.db.log_info "  finished: %s, direction: %s (%0.6fs)" %
					[ migration.description, direction, Time.now - start ]
			end
		end


		### Fetch an Array of all model classes which are descended from the migrating subclass,
		### inclusive.
		def all_migrating_model_classes
			return [ self.baseclass ] + self.baseclass.descendents
		end


		### Returns any migration objects found in the migrating subclass or any of its
		### descendents as an Array of Sequel::SimpleMigration objects, sorted by the migration
		### name and the name of its migrating class.
		def all_migrations
			migrations = self.all_migrating_model_classes.
				collect( &:migrations ).
				compact.
				inject do |all, hash|
					all.merge( hash ) do |key, old, new|
						# rely on the fact that `up` is user defined even for a change block
						fail "found duplicate `names` for migrations at #{old.up.source_location[0]} and #{new.up.source_location[0]}"
					end
			end

			return migrations.values.sort_by {|m| [m.name, m.model_class.name] }
		end


		### Returns two Arrays of migrations, the first one containing those which have already
		### been applied, and the second containing migrations which are pending. Migrations that
		### have been marked as applied but are (no longer) defined by a model class will be
		### ignored.
		def get_partitioned_migrations

			# Get the list of applied migrations for the subclass and its descendents.
			migrating_class_names = self.all_migrating_model_classes.map( &:name ).compact
			applied_map = self.dataset.
				filter( :model_class => migrating_class_names ).
				select_hash( column, :model_class )

			# Split up the migrations by whether or not it exists in the map of applied migrations.
			# Each one is removed from the map, so it can be checked for consistency
			part_migrations = self.all_migrations.partition do |migration|
				applied_map.delete( migration.name )
			end

			# If there are any "applied" migrations left, it's likely been deleted since it was
			# applied, so just ignore it.
			unless applied_map.empty?
				applied_map.each do |migration, classname|
					db.log_info "No %s migration defined in %s; ignoring it." %
						[ migration, classname ]
				end
			end

			return part_migrations
		end


		#######
		private
		#######

		### Returns the dataset for the schema_migrations table. If no such table
		### exists, it is automatically created.
		def make_schema_dataset( db, table, column )
			ds = db.from( table )
			db.log_info "Schema dataset is: %p" % [ ds ]

			if !db.table_exists?( table ) || ds.columns.empty?
				db.log_info "No migrations table: Installing one."
				db.create_table( table ) do
					String column, :primary_key => true
					String :model_class, :null => false
				end
			elsif !ds.columns.include?( column )
				raise Sequel::Error, "Migrator table %p does not contain column %p (%p)" %
					[ table, column, ds.columns ]
			end

			return ds
		end

	end # class Migrator


end # Sequel::Plugins::InlineMigrations
