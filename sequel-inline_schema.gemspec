# -*- encoding: utf-8 -*-
# stub: sequel-inline_schema 0.4.0.pre.20250731170233 ruby lib

Gem::Specification.new do |s|
  s.name = "sequel-inline_schema".freeze
  s.version = "0.4.0.pre.20250731170233".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/Sequel-InlineSchema/browse", "changelog_uri" => "http://deveiate.org/code/sequel-inline_schema/History_md.html", "documentation_uri" => "http://deveiate.org/code/sequel-inline_schema", "homepage_uri" => "https://hg.sr.ht/~ged/Sequel-InlineSchema", "source_uri" => "https://hg.sr.ht/~ged/Sequel-InlineSchema/browse" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2025-07-31"
  s.description = "This is a set of plugins for Sequel for declaring a model\u2019s table schema and any migrations in the class itself (similar to the legacy schema plugin).".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = [".document".freeze, ".rdoc_options".freeze, ".simplecov".freeze, "History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/sequel/inline_schema.rb".freeze, "lib/sequel/plugins/inline_migrations.rb".freeze, "lib/sequel/plugins/inline_schema.rb".freeze, "spec/sequel/plugins/inline_migrations_spec.rb".freeze, "spec/sequel/plugins/inline_schema_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Sequel-InlineSchema".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "This is a set of plugins for Sequel for declaring a model\u2019s table schema and any migrations in the class itself (similar to the legacy schema plugin).".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<sequel>.freeze, ["~> 5.50".freeze])
  s.add_development_dependency(%q<pg>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.19".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.13".freeze])
  s.add_development_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.3".freeze])
end
