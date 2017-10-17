require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec)

desc "by default run tests"
task :default => :test

desc "run all tests"
task :test => [:spec ]
