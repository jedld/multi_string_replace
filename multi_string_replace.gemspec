
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "multi_string_replace/version"

Gem::Specification.new do |spec|
  spec.name          = "multi_string_replace"
  spec.version       = MultiStringReplace::VERSION
  spec.authors       = ["Joseph Dayo"]
  spec.email         = ["joseph.dayo@gmail.com"]

  spec.summary       = %q{A fast multiple string replace library for ruby. Uses a C implementation of the Aho–Corasick Algorithm}
  spec.description   = %q{A fast multiple string replace library for ruby. Uses a C implementation of the Aho–Corasick Algorithm}
  spec.homepage      = "https://github.com/jedld/multi_string_replace"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/multi_string_replace/extconf.rb"]

  spec.add_development_dependency "bundler", "~> 2.3.26"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake-compiler"
end
