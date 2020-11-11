# -*- ruby -*-
# encoding: utf-8
# frozen-string-literal: true

require 'tsort'
require 'sequel'

# A replacement for Sequel's old built in schema plugin. It allows you to define
# your schema directly in the model using Model.set_schema (which takes a block
# similar to Database#create_table), and use Model.create_table to create a
# table using the schema information.
#
# ## Usage
#
# There are several ways to use this plugin.
#
# Add the schema methods to all model subclasses:
#
#     Sequel::Model.plugin :inline_schema
#
# Add the schema methods to a particular class:
#
#     Album.plugin :inline_schema
#     Album.set_schema { ... }
#     Album.create_table?
#
# Add the schema methods to an abstract base class:
#
#     # lib/acme/model.rb
#     require 'sequel'
#     require 'acme'
#
#     module ACME
#         Model = Class.new( Sequel::Model )
#         Model.def_Model( ACME )
#
#         class Model
#             plugin :inline_schema
#         end
#     end
#
#     # lib/acme/product.rb
#     require 'acme/model'
#
#     class ACME::Product < ACME::Model( :products )
#
#         set_schema do
#             primary_key :id
#             String :sku, null: false
#             String :name, null: false
#             ...
#         end
#
#     end
#
# ## Notable Model Methods
#
# See Sequel::Plugins::InlineSchema::ClassMethods for documentation for the methods the
# plugin adds to your model class/es.
#
# Of particular note:
#
# A model class with an inline schema has several methods for creating/dropping its
# associated table:
#
# * create_table
# * create_table!
# * create_table?
# * table_exists?
# * drop_table
# * drop_table?
#
# If you use it with an abstract base class, you can ask the base class which of
# its subclasses need their tables created:
#
# * uninstalled_tables
#
# It can also define hooks for creating and dropping the table:
#
# * before_create_table
# * after_create_table
# * before_drop_table
# * after_drop_table
#
# As with other Sequel
# [model hooks](http://sequel.jeremyevans.net/rdoc/files/doc/model_hooks_rdoc.html),
# you can prevent the action from the `before_*` hooks by calling `cancel_action`.
module Sequel::Plugins::InlineSchema


	### Sequel plugin API -- called the first time the plugin is loaded for this
	### +model+.
	def self::apply( model, *args ) # :nodoc:
		model.plugin( :subclasses ) # track subclasses
		model.extend( TSort )
		model.require_valid_table = false
	end


	# Sequel plugin API -- add these methods to model classes which load the plugin.
	module ClassMethods

		### Extension callback -- add some class instance variables to keep track of
		### schema info.
		def self::extended( model_class )
			super

			model_class.require_valid_table = false

			# The Sequel::Dataset used to create the model's view (if it's modelling a view
			# instead of a table). Setting this causes the model's schema to be ignored when
			# its table is created, creating a view by the same name instead.
			model_class.singleton_class.attr_accessor( :view_dataset )

			# The options used when creating the view for the model.
			model_class.singleton_class.attr_accessor( :view_options )
		end


		### Returns the table schema created with set_schema.
		def schema
			if !@schema && @schema_block
				self.set_dataset( self.db[@schema_name] ) if @schema_name
				@schema = self.db.create_table_generator( &@schema_block )
				self.set_primary_key( @schema.primary_key_name ) if @schema.primary_key_name
			end
			return @schema || ( superclass.schema unless superclass == Sequel::Model )
		end


		### Defines a table schema (see Schema::CreateTableGenerator for more information).
		###
		### This will also set the dataset if you provide a +name+, as well as setting
		### the primary key if you define one in the passed block.
		###
		### Since this plugin allows you to declare the schema inline with the model
		### class that acts as its interface, the table will not always exist when the
		### class loads, so calling #set_schema will call require_valid_table to `false`
		### for you. You can disable this by passing `require_table: true`.
		def set_schema( name=nil, require_table: false, &block )
			self.require_valid_table = require_table
			@schema = nil
			@schema_name = name
			@schema_block = block
		end


		#
		# Table utilities
		#

		### Creates table, using the column information from set_schema.
		def create_table( *args, &block )
			self.set_schema( *args, &block ) if block
			self.before_create_table
			self.db.create_table( self.table_name, generator: self.schema )
			@db_schema = get_db_schema( true )
			self.after_create_table
			return self.columns
		end


		### Drops the table if it exists and then runs create_table.  Should probably
		### not be used except in testing.
		def create_table!( *args, &block )
			self.drop_table?
			return self.create_table( *args, &block )
		end


		### Creates the table unless the table already exists
		def create_table?( *args, &block )
			self.create_table( *args, &block ) unless self.table_exists?
		end


		### Drops table. If the table doesn't exist, this will probably raise an error.
		def drop_table( opts={} )
			self.before_drop_table
			self.db.drop_table( self.table_name, opts )
			self.after_drop_table
		end


		### Drops table if it already exists, do nothing.
		def drop_table?( opts={} )
			self.drop_table( opts ) if self.table_exists?
		end


		### Returns true if table exists, false otherwise.
		def table_exists?
			return self.db.table_exists?( self.table_name )
		end


		### Set the dataset to use for the model to +ds+. If a +block+ is provided, it will be
		### called with the specified +ds+, and should return the modified dataset to use. Any
		### +options+ that are given will be passed to Sequel::Database#create_or_replace_view
		def set_view_dataset( ds=nil, **options ) # :yield: ds
			ds = yield( ds ) if block_given?

			self.view_dataset = ds
			self.view_options = options
		end


		### Create the view for this model class.
		def create_view( options={} )
			dataset = self.view_dataset or raise "No view declared for this model."
			options = self.view_options.merge( options )

			self.before_create_view
			self.db.log_info "Creating view %s(%p): %s" % [ self.table_name, options, dataset.sql ]
			self.db.create_view( self.table_name, dataset, options )
			@db_schema = get_db_schema( true )
			self.after_create_view
		end


		### Drops the view if it exists and then runs #create_view.
		def create_view!( options={} )
			self.drop_view?
			return self.create_view
		end


		### Creates the view unless it already exists.
		def create_view?( options={} )
			self.create_view( options ) unless self.view_exists?
		end


		### Refresh the view for this model class. This can only
		### be called on materialized views.
		def refresh_view
			self.db.refresh_view( self.table_name )
		end


		### Drop the view backing this model.
		def drop_view( options={} )
			self.before_drop_view
			self.db.drop_view( self.table_name, self.view_options.merge(options) )
			self.after_drop_view
		end


		### Drop the view if it already exists, otherwise do nothing.
		def drop_view?( options={} )
			self.drop_view( options ) if self.view_exists?
		end


		### Returns true if the view associated with this model exists, false otherwise.
		### :FIXME: This is PostgreSQL-specific, but there doesn't appear to be any
		### cross-driver way to check for a view.
		def view_exists?
			# Make shortcuts for fully-qualified names
			class_table = Sequel[:pg_catalog][:pg_class].as( :c )
			ns_table = Sequel[:pg_catalog][:pg_namespace].as( :n )
			is_visible = Sequel[:pg_catalog][:pg_table_is_visible]

			_, table, _ = Sequel.split_symbol( self.table_name )

			ds = db[ class_table ].
				join( ns_table, oid: :relnamespace )
			ds = ds.where( Sequel[:c][:relkind] => ['v', 'm'] ).
				exclude( Sequel[:n][:nspname] => /^pg_toast/ ).
				where( Sequel[:c][:relname] => table.to_s ).
				where( Sequel.function(is_visible, Sequel[:c][:oid]) )

			return ds.count == 1
		end



		#
		# Hooks
		#

		### Table-creation hook; called on a model class before its table is created.
		def before_create_table
			return true
		end


		### Table-creation hook; called on a model class after its table is created.
		def after_create_table
			return true
		end


		### View-creation hook; called before the backing view is created.
		def before_create_view
			return true
		end


		### View-creation hook; called after the backing view is created.
		def after_create_view
			return true
		end


		### Table-drop hook; called before the table is dropped.
		def before_drop_table
			return true
		end


		### Table-drop hook; called after the table is dropped.
		def after_drop_table
			return true
		end


		### View-creation hook; called before the backing view is created.
		def before_create_view
			return true
		end


		### View-creation hook; called after the backing view is created.
		def after_create_view
			return true
		end


		### View-drop hook; called before the backing view is dropped.
		def before_drop_view
			return true
		end


		### View-drop hook; called after the backing view is dropped.
		def after_drop_view
			return true
		end


		#
		# Schema-state introspection
		#

		### Return an Array of model classes whose tables don't yet exist, in the order they
		### need to be created to satisfy foreign key constraints.
		def uninstalled_tables
			self.db.log_info "  searching for unbacked model classes..."

			self.tsort.find_all do |modelclass|
				next unless modelclass.name && modelclass.name != '' && !modelclass.is_view_class?
				!modelclass.table_exists?
			end.uniq( &:table_name )
		end


		### Return an Array of model classes whose views don't yet exist, in the order
		### they need to be created.
		def uninstalled_views
			return self.tsort.find_all( &:is_view_class? ).reject( &:table_exists? )
		end


		### Return an Array of model classes whose views exist, in the order they need to be
		### created.
		def installed_views
			return self.tsort.find_all( &:is_view_class? ).select( &:table_exists? )
		end


		### Returns +true+ if the receiver is defined via a view rather than a table.
		def is_view_class?
			return self.respond_to?( :view_dataset ) && self.view_dataset ? true : false
		end


		#########
		protected
		#########

		### Raise an appropriate Sequel::HookFailure exception for the specified +type+.
		def raise_hook_failure( type=nil )
			msg = case type
				when String
					type
				when Symbol
					"the #{type} hook failed"
				else
					"a hook failed"
				end

			raise Sequel::HookFailed.new( msg, self )
		end


		### Cancel the currently-running before_* hook. If a +msg+ is given, use it when
		### constructing the HookFailed exception.
		def cancel_action( msg=nil )
			self.raise_hook_failure( msg )
		end


		### TSort API -- yield each model class.
		def tsort_each_node( &block )
			self.descendents.select( &:name ).each( &block )
		end


		### TSort API -- yield each of the given +model_class+'s dependent model
		### classes.
		def tsort_each_child( model_class ) # :yields: model_class
			# Include (non-anonymous) parents other than Model
			model_class.ancestors[1..-1].
				select {|cl| cl < self }.
				select( &:name ).
				each do |parentclass|
					yield( parentclass )
				end

			# Include associated classes for which this model class's table has a
			# foreign key
			model_class.association_reflections.each do |name, config|
				next if config[:polymorphic]

				associated_class = config.associated_class

				yield( associated_class ) if config[:type] == :many_to_one
			end
		end

	end # module ClassMethods

end # module Sequel::Plugin::Schema
