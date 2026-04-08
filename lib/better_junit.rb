# frozen_string_literal: true

require 'minitest/reporters'
require 'builder'
require 'fileutils'
require 'pathname'
require 'time'

module MinitestPlus
  class BetterJUnit < Minitest::Reporters::BaseReporter # rubocop:disable Metrics/ClassLength,Style/Documentation
    DEFAULT_PATH = 'test/reports/junit.xml'

    def initialize(options = {})
      super({})
      @path = options[:path] || DEFAULT_PATH
      @base_path = options[:base_path] || Dir.pwd
      @include_timestamp = options[:include_timestamp] || false
    end

    def report
      super
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, build_xml)
    end

    private

    def build_xml
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      xml.testsuites do
        tests.group_by { |test| test_class(test) }.each do |suite, suite_tests|
          parse_xml_for(xml, suite, suite_tests) if suite
        end
      end
      xml.target!
    end

    def get_source_location(result)
      result.source_location
    end

    def get_relative_path(result)
      file_path = Pathname.new(get_source_location(result).first)
      base_path = Pathname.new(@base_path)

      if file_path.absolute?
        file_path.relative_path_from(base_path)
      else
        file_path
      end
    end

    # rubocop:disable Metrics/MethodLength
    def parse_xml_for(xml, suite, tests)
      stats = analyze_suite(tests)
      file_path = get_relative_path(tests.first)
      attrs = testsuite_attributes(suite, file_path, stats)

      xml.testsuite(attrs) do
        tests.each do |test|
          xml.testcase(testcase_attributes(test, suite, file_path)) do
            message = xml_message_for(test)
            xml << message if message
            xml << xml_attachment_for(test) if test.respond_to?('metadata') && test.metadata[:failure_screenshot_path]
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def testsuite_attributes(suite, file_path, stats)
      attrs = {
        name: suite.name, filepath: file_path.to_s, skipped: stats[:skip_count],
        failures: stats[:fail_count], errors: stats[:error_count],
        tests: stats[:test_count], assertions: stats[:assertion_count],
        time: stats[:time]
      }
      attrs[:timestamp] = stats[:timestamp] if @include_timestamp && stats[:timestamp]
      attrs
    end

    def testcase_attributes(test, suite, file_path)
      {
        name: test.name, lineno: get_source_location(test).last, classname: suite.name,
        assertions: test.assertions, time: test.time, file: file_path.to_s
      }
    end

    def xml_attachment_for(test)
      xml = Builder::XmlMarkup.new(indent: 2, margin: 2)
      xml.tag!('system-out', "[[ATTACHMENT|#{test.metadata[:failure_screenshot_path]}]]")
      xml.target!
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def xml_message_for(test)
      failure = test.failure
      return nil unless failure

      xml = Builder::XmlMarkup.new(indent: 2, margin: 2)

      if test.skipped?
        xml.skipped(type: failure.error.class.name)
      elsif test.error?
        xml.error(type: failure.error.class.name, message: trunc(failure.message)) do
          xml.text!(message_for(test, failure) || '')
        end
      else
        xml.failure(type: failure.error.class.name, message: trunc(failure.message)) do
          xml.text!(message_for(test, failure) || '')
        end
      end

      xml.target!
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def trunc(text)
      text.sub(/\n.*/m, '...')
    end

    def message_for(test, failure)
      suite = test.class
      name = test.name

      if test.skipped?
        "Skipped:\n#{name}(#{suite}) [#{location(failure)}]:\n#{failure.message}\n"
      elsif test.error?
        "Error:\n#{name}(#{suite}):\n#{failure.message}"
      else
        "Failure:\n#{name}(#{suite}) [#{location(failure)}]:\n#{failure.message}\n"
      end
    end

    def location(failure)
      last_before_assertion = ''
      failure.backtrace.reverse_each do |s|
        break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/

        last_before_assertion = s
      end
      last_before_assertion.sub(/:in .*$/, '')
    end

    def analyze_suite(tests)
      stats = Hash.new(0)
      stats[:time] = 0.0
      tests.each do |test|
        stats[:"#{result(test)}_count"] += 1
        stats[:assertion_count] += test.assertions
        stats[:test_count] += 1
        stats[:time] += test.time
      end
      stats[:timestamp] = Time.now.iso8601 if @include_timestamp
      stats
    end
  end
end
