require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new "multi_string_replace" do |ext|
  ext.lib_dir = "lib/multi_string_replace"
end

task :default => :spec
