# frozen_string_literal: true

require 'minitest/autorun'
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/reporters'
require_relative '../lib/better_coverage'

Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new, # Shows test results
  MinitestPlus::BetterCoverage.new # Shows coverage
]
