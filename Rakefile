require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec_live) do |t|
  t.rspec_opts = "--tag live"
end

RSpec::Core::RakeTask.new(:spec_performance) do |t|
  t.rspec_opts = "--tag performance"
end

desc "by default run tests"
task :default => :test

desc "run all tests"
task :test => [:spec ]

desc "run live tests"
task :live_test => [ :spec_live ]

desc "run performance tests"
task :performance_test => [ :spec_performance ]
