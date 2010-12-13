# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tmail}
  s.version = "1.2.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mikel Lindsaar <raasdnil AT gmail.com>"]
  s.date = %q{2010-01-06}
  s.description = %q{TMail is a Ruby-based mail handler. It allows you to compose stadards compliant emails in a very Ruby-way.}
  s.email = %q{raasdnil AT gmail.com}
  s.extensions = ["ext/tmailscanner/tmail/extconf.rb"]
  s.extra_rdoc_files = ["README.rdoc", "CHANGES", "LICENSE", "NOTES", "Rakefile"]
  s.files = %w(README.rdoc Rakefile NOTES CHANGES LICENSE setup.rb tmail.gemspec) +
            Dir.glob("lib/**/*") + Dir.glob("ext/**/*")
  s.has_rdoc = true
  s.homepage = %q{http://tmail.rubyforge.org}
  s.rdoc_options = ["--inline-source", "--title", "TMail", "--main", "README.rdoc"]
  s.require_paths = ["lib", "ext/tmailscanner"]
  s.rubyforge_project = %q{tmail}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby Mail Handler}
  s.test_files = Dir.glob("test/**/*")

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
