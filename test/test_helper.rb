# frozen_string_literal: true

require 'minitest/autorun'
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/reporters'
require_relative '../lib/better_coverage'

Minitest::Reporters.use! [
  MinitestPlus::BetterCoverage.new,
  Minitest::Reporters::SpecReporter.new(color: true),
  Minitest::Reporters::JUnitReporter.new('build/reports/', true, single_file: true)
]
