# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = true
end
task default: :test

Rake::TestTask.new(:bench) do |test|
  test.pattern = 'test/benchmark_test.rb'
end

begin
  require 'duel/rake_task'
  Duel::RakeTask.new
rescue LoadError
  # Duel requires Ruby 3.4 or later
end
