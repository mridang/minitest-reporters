# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

# Set the base coverage directory and apply filters
SimpleCov.coverage_dir('build/coverage')

# Set up multiple formatters: HTML and LCOV
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter.new(output_dir: File.join(SimpleCov.coverage_path, 'html')),
    SimpleCov::Formatter::CoberturaFormatter
  ]
)

SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/better_coverage'
require_relative '../lib/better_junit'

Minitest::Reporters.use! [
  MinitestPlus::BetterCoverage.new,
  Minitest::Reporters::SpecReporter.new(color: true),
  MinitestPlus::BetterJUnit.new(path: 'build/reports/junit.xml')
]
