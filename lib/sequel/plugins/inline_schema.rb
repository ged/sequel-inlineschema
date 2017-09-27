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
# Usage:
#
#	 # Add the schema methods to all model subclasses
#	 Sequel::Model.plugin :inline_schema
#
#	 # Add the schema methods to the Album class
#	 Album.plugin :inline_schema
#    Album.set_schema { ... }
#    Album.create_table?
#
module Sequel::Plugins::InlineSchema


	### Sequel plugin API -- called the first time the plugin is loaded for this
	### +model+.
	def self::apply( model, *args )
		model.plugin( :subclasses ) # track subclasses
		model.extend( TSort )
		model.require_valid_table = false
	end


	# Sequel plugin API -- add these methods to model classes which load the plugin.
	module ClassMethods

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


		### Called before the table is created.
		def before_create_table
			# No-op
		end


		### Called after the table is created.
		def after_create_table
			# No-op
		end


		### Drops table. If the table doesn't exist, this will probably raise an error.
		def drop_table
			self.db.drop_table( self.table_name )
		end


		### Drops table if it already exists, do nothing if it doesn't exist.
		def drop_table?
			self.db.drop_table?( self.table_name )
		end


		### Returns table schema created with set_schema for direct descendant of Model.
		### Does not retrieve schema information from the database, see db_schema if you
		### want that.
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
		### This is only needed if you want to use the create_table/create_table! methods.
		### Will also set the dataset if you provide a name, as well as setting
		### the primary key if you defined one in the passed block.
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


		### Returns true if table exists, false otherwise.
		def table_exists?
			return self.db.table_exists?( self.table_name )
		end


		### Table-creation hook; called on a model class before its table is created.
		def before_create_table
			return true
		end


		### Table-creation hook; called on a model class after its table is created.
		def after_create_table
			return true
		end


		### Return an Array of model table names that don't yet exist, in the order they
		### need to be created to satisfy foreign key constraints.
		def uninstalled_tables
			self.db.log_info "  searching for unbacked model classes..."

			self.tsort.find_all do |modelclass|
				next unless modelclass.name && modelclass.name != ''
				!modelclass.table_exists?
			end.uniq( &:table_name )
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
