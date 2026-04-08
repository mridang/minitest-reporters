# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'
require 'rexml/document'
require_relative '../lib/better_junit'

# rubocop:disable Metrics/ClassLength
class BetterJUnitTest < Minitest::Test
  FakeFailure = Struct.new(:error, :message, :backtrace)

  FakeTest = Struct.new(
    :name, :assertions, :time, :passed, :skipped, :errored, :failure, :source_location, :metadata
  ) do
    def passed?
      passed
    end

    def skipped?
      skipped
    end

    def error?
      errored
    end
  end

  def passed_test(name: 'test_passes', file: 'lib/example.rb', lineno: 5, assertions: 1, time: 0.01)
    FakeTest.new(name, assertions, time, true, false, false, nil, [File.join(Dir.pwd, file), lineno], {})
  end

  def failed_test(name: 'test_fails', file: 'lib/example.rb', lineno: 7, message: 'expected true got false')
    err = StandardError.new(message)
    backtrace = ["#{file}:#{lineno}:in `block in #{name}'", "minitest/assertions.rb:42:in `assert'"]
    failure = FakeFailure.new(err, message, backtrace)
    FakeTest.new(name, 1, 0.02, false, false, false, failure, [File.join(Dir.pwd, file), lineno], {})
  end

  def errored_test(name: 'test_errors', file: 'lib/example.rb', lineno: 9, message: 'kaboom')
    err = ArgumentError.new(message)
    backtrace = ["#{file}:#{lineno}:in `block in #{name}'"]
    failure = FakeFailure.new(err, message, backtrace)
    FakeTest.new(name, 0, 0.03, false, false, true, failure, [File.join(Dir.pwd, file), lineno], {})
  end

  def skipped_test(name: 'test_skips', file: 'lib/example.rb', lineno: 11, message: 'not yet')
    err = Minitest::Skip.new(message)
    failure = FakeFailure.new(err, message, [])
    FakeTest.new(name, 0, 0.001, false, true, false, failure, [File.join(Dir.pwd, file), lineno], {})
  end

  def setup
    @reporter = MinitestPlus::BetterJUnit.new
  end

  def test_initialize_with_defaults
    reporter = MinitestPlus::BetterJUnit.new

    assert_equal 'test/reports/junit.xml', reporter.instance_variable_get(:@path)
    assert_equal Dir.pwd, reporter.instance_variable_get(:@base_path)
    refute reporter.instance_variable_get(:@include_timestamp)
  end

  def test_initialize_with_options
    reporter = MinitestPlus::BetterJUnit.new(
      path: 'build/reports/custom.xml',
      base_path: '/tmp',
      include_timestamp: true
    )

    assert_equal 'build/reports/custom.xml', reporter.instance_variable_get(:@path)
    assert_equal '/tmp', reporter.instance_variable_get(:@base_path)
    assert reporter.instance_variable_get(:@include_timestamp)
  end

  def test_default_path_constant
    assert_equal 'test/reports/junit.xml', MinitestPlus::BetterJUnit::DEFAULT_PATH
  end

  # rubocop:disable Metrics/AbcSize
  def test_analyze_suite_counts_all_outcomes # rubocop:disable Minitest/MultipleAssertions
    tests = [passed_test(assertions: 3, time: 0.10), failed_test, errored_test, skipped_test]

    result = @reporter.send(:analyze_suite, tests)

    assert_equal 4, result[:test_count]
    assert_equal 4, result[:assertion_count]
    assert_equal 1, result[:pass_count]
    assert_equal 1, result[:fail_count]
    assert_equal 1, result[:error_count]
    assert_equal 1, result[:skip_count]
    assert_in_delta 0.151, result[:time], 0.001
  end
  # rubocop:enable Metrics/AbcSize

  def test_analyze_suite_includes_timestamp_when_enabled
    @reporter.instance_variable_set(:@include_timestamp, true)

    result = @reporter.send(:analyze_suite, [passed_test])

    assert_kind_of String, result[:timestamp]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:timestamp])
  end

  def test_analyze_suite_omits_timestamp_by_default
    result = @reporter.send(:analyze_suite, [passed_test])

    refute result.key?(:timestamp)
  end

  def test_get_relative_path_with_absolute_path
    test = passed_test(file: 'lib/foo.rb')

    assert_equal 'lib/foo.rb', @reporter.send(:get_relative_path, test).to_s
  end

  def test_get_relative_path_with_relative_path
    test = FakeTest.new('test', 1, 0.0, true, false, false, nil, ['lib/bar.rb', 1], {})

    assert_equal 'lib/bar.rb', @reporter.send(:get_relative_path, test).to_s
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_build_xml_emits_required_testsuite_attributes # rubocop:disable Minitest/MultipleAssertions
    @reporter.tests = [passed_test, failed_test, errored_test, skipped_test]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    suite = doc.root.elements['testsuite']

    assert_equal 'testsuites', doc.root.name
    assert_equal 'BetterJUnitTest::FakeTest', suite.attributes['name']
    assert_equal 'lib/example.rb', suite.attributes['filepath']
    assert_equal '4', suite.attributes['tests']
    assert_equal '2', suite.attributes['assertions']
    assert_equal '1', suite.attributes['failures']
    assert_equal '1', suite.attributes['errors']
    assert_equal '1', suite.attributes['skipped']
    refute_nil suite.attributes['time']
    assert_nil suite.attributes['timestamp']
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  def test_build_xml_emits_required_testcase_attributes # rubocop:disable Minitest/MultipleAssertions
    @reporter.tests = [passed_test(name: 'test_alpha', lineno: 42, assertions: 7, time: 0.5)]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    testcase = doc.root.elements['testsuite/testcase']

    assert_equal 'test_alpha', testcase.attributes['name']
    assert_equal '42', testcase.attributes['lineno']
    assert_equal 'BetterJUnitTest::FakeTest', testcase.attributes['classname']
    assert_equal '7', testcase.attributes['assertions']
    assert_equal '0.5', testcase.attributes['time']
    assert_equal 'lib/example.rb', testcase.attributes['file']
  end
  # rubocop:enable Metrics/AbcSize

  def test_build_xml_includes_timestamp_attribute_when_enabled
    reporter = MinitestPlus::BetterJUnit.new(include_timestamp: true)
    reporter.tests = [passed_test]

    doc = REXML::Document.new(reporter.send(:build_xml))
    suite = doc.root.elements['testsuite']

    refute_nil suite.attributes['timestamp']
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, suite.attributes['timestamp'])
  end

  def test_build_xml_groups_multiple_suites_under_single_testsuites_root
    suite_a = passed_test(name: 'a')
    suite_b_class = Class.new(FakeTest) { def self.name = 'OtherSuite' }
    suite_b = suite_b_class.new('b', 1, 0.01, true, false, false, nil, [File.join(Dir.pwd, 'lib/example.rb'), 5], {})
    @reporter.tests = [suite_a, suite_b]

    doc = REXML::Document.new(@reporter.send(:build_xml))

    assert_equal 'testsuites', doc.root.name
    assert_equal 2, doc.root.elements.to_a('testsuite').size
  end

  # rubocop:disable Metrics/AbcSize
  def test_build_xml_emits_failure_element_for_failed_test # rubocop:disable Minitest/MultipleAssertions
    @reporter.tests = [failed_test(message: 'boom!')]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    failure = doc.root.elements['testsuite/testcase/failure']

    refute_nil failure
    assert_equal 'StandardError', failure.attributes['type']
    assert_equal 'boom!', failure.attributes['message']
    assert_includes failure.text, 'Failure:'
    assert_includes failure.text, 'test_fails'
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def test_build_xml_emits_error_element_for_errored_test # rubocop:disable Minitest/MultipleAssertions
    @reporter.tests = [errored_test(message: 'crashed')]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    error = doc.root.elements['testsuite/testcase/error']

    refute_nil error
    assert_equal 'ArgumentError', error.attributes['type']
    assert_equal 'crashed', error.attributes['message']
    assert_includes error.text, 'Error:'
    assert_includes error.text, 'test_errors'
  end
  # rubocop:enable Metrics/AbcSize

  def test_build_xml_emits_skipped_element_for_skipped_test
    @reporter.tests = [skipped_test]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    skipped = doc.root.elements['testsuite/testcase/skipped']

    refute_nil skipped
    assert_equal 'Minitest::Skip', skipped.attributes['type']
  end

  def test_build_xml_emits_attachment_for_screenshot_metadata
    test = failed_test
    test.metadata = { failure_screenshot_path: '/tmp/screenshot.png' }
    @reporter.tests = [test]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    system_out = doc.root.elements['testsuite/testcase/system-out']

    refute_nil system_out
    assert_includes system_out.text, '[[ATTACHMENT|/tmp/screenshot.png]]'
  end

  def test_build_xml_truncates_multiline_failure_message_in_attribute
    test = failed_test(message: "first line\nsecond line\nthird line")
    @reporter.tests = [test]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    failure = doc.root.elements['testsuite/testcase/failure']

    assert_equal 'first line...', failure.attributes['message']
  end

  def test_build_xml_omits_failure_children_for_passing_tests
    @reporter.tests = [passed_test]

    doc = REXML::Document.new(@reporter.send(:build_xml))
    testcase = doc.root.elements['testsuite/testcase']

    assert_nil testcase.elements['failure']
    assert_nil testcase.elements['error']
    assert_nil testcase.elements['skipped']
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def test_report_writes_well_formed_file_to_configured_path
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'nested', 'junit.xml')
      reporter = MinitestPlus::BetterJUnit.new(path: path)
      reporter.start
      reporter.tests = [passed_test]

      reporter.report

      assert_path_exists path
      doc = REXML::Document.new(File.read(path))

      assert_equal 'testsuites', doc.root.name
      assert_equal 1, doc.root.elements.to_a('testsuite').size
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def test_report_creates_default_directory_when_missing
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        reporter = MinitestPlus::BetterJUnit.new
        reporter.start
        reporter.tests = [passed_test]

        reporter.report

        assert_path_exists File.join(dir, 'test/reports/junit.xml')
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
