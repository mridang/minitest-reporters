# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'steep/rake_task'

RuboCop::RakeTask.new(:rubocop)

Steep::RakeTask.new(:steep) do |task|
  task.check.severity_level = :error
end

Rake::TestTask.new(:test) do |task|
  task.libs << 'lib' << 'test'
  task.pattern = 'test/**/*_test.rb'
  task.verbose = false
end

task default: :test
