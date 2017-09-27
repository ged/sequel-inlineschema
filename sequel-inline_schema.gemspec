# -*- encoding: utf-8 -*-
# stub: sequel-inline_schema 0.1.0.pre20170927120043 ruby lib

Gem::Specification.new do |s|
  s.name = "sequel-inline_schema".freeze
  s.version = "0.1.0.pre20170927120043"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2017-09-27"
  s.description = "This is a plugin for declaring a model's table schema inline with the class\nitself, similar to the legacy `schema` plugin.".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "LICENSE.txt".freeze, "Manifest.txt".freeze, "README.md".freeze, "History.md".freeze, "README.md".freeze]
  s.files = [".document".freeze, ".editorconfig".freeze, ".rdoc_options".freeze, ".simplecov".freeze, "ChangeLog".freeze, "History.md".freeze, "LICENSE.txt".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/sequel/inline_schema.rb".freeze, "lib/sequel/plugins/inline_migrations.rb".freeze, "lib/sequel/plugins/inline_schema.rb".freeze, "spec/sequel/plugins/inline_migrations_spec.rb".freeze, "spec/sequel/plugins/inline_schema_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "http://deveiate.org/projects/sequel-inline_schema".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "2.6.13".freeze
  s.summary = "This is a plugin for declaring a model's table schema inline with the class itself, similar to the legacy `schema` plugin.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel>.freeze, ["~> 5.0"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.13"])
      s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.16"])
    else
      s.add_dependency(%q<sequel>.freeze, ["~> 5.0"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.13"])
      s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<sequel>.freeze, ["~> 5.0"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.13"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.3"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
  end
end
