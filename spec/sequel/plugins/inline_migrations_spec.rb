#!/usr/bin/env rspec -cfd

require_relative '../../spec_helper'

require 'sequel'
require 'sequel/model'
require 'sequel/inline_schema'
require 'sequel/plugins/inline_migrations'

RSpec.describe Sequel::Plugins::InlineMigrations do

	let( :db ) { Sequel.connect('mock://postgres', logger: Loggability[Sequel::InlineSchema]) }

	let( :model_class ) do
		cls = Class.new( Sequel::Model ) do
			def self::name; "Thing"; end
		end
		cls.dataset = db[:things]
		cls.plugin( :inline_migrations )
		cls
	end


	it "also adds the 'subclasses' and 'inline_schema' plugins to including models" do
		expect( model_class ).to respond_to( :create_table )
		expect( model_class ).to respond_to( :descendents )
	end


	it "allows a migration to be defined for the class" do
		model_class.migration( '20110308_1335_simple', "A very simple migration." ) do
			change do
				alter_table(:things) do
					add_column :age, :number
				end
			end
		end

		migrations = model_class.migrations

		expect( migrations.size ).to eq( 1 )
		expect( migrations ).to have_key( '20110308_1335_simple' )
		expect( migrations['20110308_1335_simple'] ).to be_a( Sequel::SimpleMigration )
		expect( migrations['20110308_1335_simple'].name ).to eq( '20110308_1335_simple' )
		expect( migrations['20110308_1335_simple'].model_class ).to eq( model_class )
		expect( migrations['20110308_1335_simple'].description ).to eq( 'A very simple migration.' )
	end


	it "adds existing migrations to the migrations table on table creation" do
		model_class.migration( '20110404_1817_index_name', "Add an index to the name field" ) do
			change do
				alter_table(:things) do
					add_index :name
				end
			end
		end

		model_class.db.columns = [ :name, :model_class ]
		model_class.db.fetch = nil

		model_class.create_table

		expect( model_class.db.sqls.last ).to eq(
			%Q{INSERT INTO "schema_migrations" ("name", "model_class") } +
			%Q{VALUES ('20110404_1817_index_name', 'Thing') RETURNING "id"}
		)
	end


	it "ignores migrations which have been removed" do
		db.fetch = {
			name: '20140603_1139_add_unique_email_constraint',
			model_class: model_class.name
		}

		migrator = model_class.migrator
		migrations = migrator.get_partitioned_migrations

		expect( migrations ).to be_an( Array )
		expect( migrations.size ).to eq( 2 )
		expect( migrations ).to all( be_empty )
	end


	it "can migrate up" do
		model_class.migration( '20110308_1335_simple', "A very simple migration." ) do
			change do
				alter_table(:things) do
					add_column :age, :number
				end
			end
		end

		model_class.migrate

		expect( db.sqls ).to include(
			%Q{ALTER TABLE "things" ADD COLUMN "age" number}
		)
	end


	it "doesn't try to apply already-applied migrations" do
		model_class.migration( '20110308_1335_simple', "A very simple migration." ) do
			change do
				alter_table(:things) do
					add_column :age, :number
				end
			end
		end
		model_class.migration( '20110711_1623_another_simple', "A later simple migration." ) do
			change do
				alter_table(:things) do
					add_column :strength, :number
				end
			end
		end

		db.fetch = Proc.new do |query|
			case query
			when /SELECT .* FROM "schema_migrations"/
				[{name: '20110308_1335_simple', model_class: 'Things'}]
			else
				[]
			end
		end
		model_class.migrate

		statements = db.sqls
		expect( statements ).to_not include(
			%Q{ALTER TABLE "things" ADD COLUMN "age" number}
		)
		expect( statements ).to include(
			%Q{ALTER TABLE "things" ADD COLUMN "strength" number}
		)
	end


	it "can migrate up to a particular migration" do
		model_class.migration( '20110308_1335_simple', "A very simple migration." ) do
			change do
				alter_table(:things) do
					add_column :age, :number
				end
			end
		end
		model_class.migration( '20110711_1623_another_simple', "A later simple migration." ) do
			change do
				alter_table(:things) do
					add_column :strength, :number
				end
			end
		end

		model_class.migrate( '20110308_1335_simple' )

		statements = db.sqls
		expect( statements ).to include(
			%Q{ALTER TABLE "things" ADD COLUMN "age" number}
		)
		expect( statements ).to_not include(
			%Q{ALTER TABLE "things" ADD COLUMN "strength" number}
		)
	end


	it "can reverse migrate down to a particular migration" do
		model_class.migration( '20110308_1335_simple', "A very simple migration." ) do
			change do
				alter_table(:things) do
					add_column :age, :number
				end
			end
		end
		model_class.migration( '20110711_1623_another_simple', "A later simple migration." ) do
			change do
				alter_table(:things) do
					add_column :strength, :number
				end
			end
		end

		db.fetch = Proc.new do |query|
			case query
			when /SELECT .* FROM "schema_migrations"/
				[{name: '20110308_1335_simple', model_class: 'Things'}]
			else
				[]
			end
		end
		model_class.migrate( '20110308_1335_simple' )

		statements = db.sqls
		expect( statements ).to include(
			%Q{ALTER TABLE "things" DROP COLUMN "age"}
		)
		expect( statements ).to_not include(
			%Q{ALTER TABLE "things" DROP COLUMN "strength"}
		)
	end


	describe "hooks" do

		let( :model_class ) do
			class_obj = super()
			class_obj.migration( '20110308_1335_simple', "A very simple migration." ) do
				change do
					alter_table(:things) do
						add_column :age, :number
					end
				end
			end
			class_obj.singleton_class.send( :attr_accessor, :called )
			class_obj.called = {}
			class_obj
		end


		it "calls a hook before applying pending migrations" do
			def model_class.before_migration
				self.called[ :before_migration ] = true
				super
			end

			model_class.migrate

			expect( model_class.called ).to include( :before_migration )
		end


		it "allows cancellation of migration from the before_migration hook" do
			def model_class.before_migration
				self.called[ :before_migration ] = true
				cancel_action
			end

			expect {
				model_class.migrate
			}.to raise_error( Sequel::HookFailed, /hook failed/i )
		end


		it "allows cancellation of migration with a message from the before_migration hook" do
			def model_class.before_migration
				self.called[ :before_migration ] = true
				cancel_action( "Wait, don't migrate yet!" )
			end

			expect {
				model_class.migrate
			}.to raise_error( Sequel::HookFailed, "Wait, don't migrate yet!" )
		end


		it "allows cancellation of migration with a Symbol from the before_migration hook" do
			def model_class.before_migration
				self.called[ :before_migration ] = true
				cancel_action( :before_migration )
			end

			expect {
				model_class.migrate
			}.to raise_error( Sequel::HookFailed, /before_migration/ )
		end


		it "calls a hook after migration" do
			def model_class.after_migration
				self.called[ :after_migration ] = true
				super
			end

			model_class.migrate

			expect( model_class.called ).to include( :after_migration )
		end

	end

end

# vim: set nosta noet ts=4 sw=4:
