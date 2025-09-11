"# Load Bundler gem tasks only when needed to avoid conflicts between system Bundler and gem-installed Bundler"
if (ARGV & %w[build release install release:guard_clean release:rubygem_push]).any?
  require "bundler/gem_tasks"
end

require "rake/extensiontask"

# Try to load RSpec only if available; keep compile working without it
have_rspec = true
begin
  require "rspec/core/rake_task"
rescue LoadError
  have_rspec = false
end

if have_rspec
  RSpec::Core::RakeTask.new(:spec)
end

Rake::ExtensionTask.new "multi_string_replace" do |ext|
  ext.lib_dir = "lib/multi_string_replace"
end

task :default => (have_rspec ? :spec : :compile)
