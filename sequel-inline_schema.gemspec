# -*- encoding: utf-8 -*-
# stub: sequel-inline_schema 0.4.0.pre.20200211131429 ruby lib

Gem::Specification.new do |s|
  s.name = "sequel-inline_schema".freeze
  s.version = "0.4.0.pre.20200211131429"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2020-02-11"
  s.description = "This is a set of plugins for Sequel for declaring a model's table schema and\nany migrations in the class itself (similar to the legacy <code>schema</code> plugin).".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = [".document".freeze, ".rdoc_options".freeze, ".simplecov".freeze, "History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/sequel/inline_schema.rb".freeze, "lib/sequel/plugins/inline_migrations.rb".freeze, "lib/sequel/plugins/inline_schema.rb".freeze, "spec/sequel/plugins/inline_migrations_spec.rb".freeze, "spec/sequel/plugins/inline_schema_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Sequel-InlineSchema".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.5".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "This is a set of plugins for Sequel for declaring a model's table schema and any migrations in the class itself (similar to the legacy <code>schema</code> plugin).".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<sequel>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<pg>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.5"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.13"])
    s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
  else
    s.add_dependency(%q<sequel>.freeze, ["~> 5.0"])
    s.add_dependency(%q<pg>.freeze, ["~> 1.2"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.5"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.13"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
  end
end
