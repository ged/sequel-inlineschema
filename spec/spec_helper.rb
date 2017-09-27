# -*- ruby -*-
#encoding: utf-8

require 'simplecov' if ENV['COVERAGE']

require 'pg'
require 'rspec'
require 'sequel'
require 'loggability/spechelpers'


# Mock with RSpec
RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	config.include( Loggability::SpecHelpers )
end


