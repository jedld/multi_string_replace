# Load Bundler gem tasks only when needed to avoid conflicts between system Bundler and gem-installed Bundler
if (ARGV & %w[build release install release:guard_clean release:rubygem_push]).any?
  require "bundler/gem_tasks"
end
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new "multi_string_replace" do |ext|
  ext.lib_dir = "lib/multi_string_replace"
end

task :default => :spec
