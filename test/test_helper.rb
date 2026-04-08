# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

# Override the HTMLFormatter so that it writes its report inside build/coverage/html
module SimpleCov
  module Formatter
    module HTMLFormatterPatch
      def output_path
        File.join(SimpleCov.coverage_path, 'html')
      end
    end

    class HTMLFormatter
      prepend HTMLFormatterPatch
    end
  end
end

# Set up multiple formatters: HTML and LCOV
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ]
)

# Set the base coverage directory and apply filters
SimpleCov.coverage_dir('build/coverage')
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
