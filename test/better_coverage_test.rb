# frozen_string_literal: true

require_relative 'test_helper'

class BetterCoverageTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  def setup
    @reporter = MinitestPlus::BetterCoverage.new
  end

  def test_initialize_with_defaults
    reporter = MinitestPlus::BetterCoverage.new

    assert_equal 80, reporter.instance_variable_get(:@max_cols)
    refute reporter.instance_variable_get(:@skip_empty)
    refute reporter.instance_variable_get(:@skip_full)
  end

  def test_initialize_with_options
    reporter = MinitestPlus::BetterCoverage.new(max_cols: 120, skip_empty: true, skip_full: true)

    assert_equal 120, reporter.instance_variable_get(:@max_cols)
    assert reporter.instance_variable_get(:@skip_empty)
    assert reporter.instance_variable_get(:@skip_full)
  end

  def test_constants # rubocop:disable Minitest/MultipleAssertions
    assert_equal 4, MinitestPlus::BetterCoverage::NAME_COL
    assert_equal 7, MinitestPlus::BetterCoverage::PCT_COLS
    assert_equal 17, MinitestPlus::BetterCoverage::MISSING_COL
    assert_equal 1, MinitestPlus::BetterCoverage::TAB_SIZE
    assert_equal ' | ', MinitestPlus::BetterCoverage::DELIM
  end

  def test_fill_left_aligned
    result = @reporter.send(:fill, 'test', 10)

    assert_equal 'test      ', result
  end

  def test_fill_right_aligned
    result = @reporter.send(:fill, 'test', 10, right: true)

    assert_equal '      test', result
  end

  def test_fill_with_tabs
    result = @reporter.send(:fill, 'test', 10, tabs: 2)

    assert_equal '  test    ', result
  end

  def test_fill_truncates_long_text
    result = @reporter.send(:fill, 'verylongtext', 8)

    assert_equal '...gtext', result
  end

  def test_fill_numeric_input
    result = @reporter.send(:fill, 95.5, 7, right: true)

    assert_equal '   95.5', result
  end

  def test_make_line
    result = @reporter.send(:make_line, 10, 5)
    expected = '-----------|---------|-------'

    assert_equal expected, result
  end

  def test_table_header
    result = @reporter.send(:table_header, 20, 17)

    assert_includes result, 'File'
    assert_includes result, '% Lines'
    assert_includes result, 'Uncovered Line #s'
  end

  def test_colorize_by_coverage_green
    result = @reporter.send(:colorize_by_coverage, 'test', 85)

    assert_equal "\e[32mtest\e[0m", result
  end

  def test_colorize_by_coverage_yellow
    result = @reporter.send(:colorize_by_coverage, 'test', 65)

    assert_equal "\e[33mtest\e[0m", result
  end

  def test_colorize_by_coverage_red
    result = @reporter.send(:colorize_by_coverage, 'test', 45)

    assert_equal "\e[31mtest\e[0m", result
  end

  def test_colorize_uncovered_full_coverage
    result = @reporter.send(:colorize_uncovered, 'test', 100)

    assert_equal 'test', result
  end

  def test_colorize_uncovered_partial_coverage
    result = @reporter.send(:colorize_uncovered, 'test', 85)

    assert_equal "\e[31mtest\e[0m", result
  end

  def test_green
    result = @reporter.send(:green, 'test')

    assert_equal "\e[32mtest\e[0m", result
  end

  def test_yellow
    result = @reporter.send(:yellow, 'test')

    assert_equal "\e[33mtest\e[0m", result
  end

  def test_red
    result = @reporter.send(:red, 'test')

    assert_equal "\e[31mtest\e[0m", result
  end

  def test_build_tree_single_file
    tree = @reporter.send(:build_tree, [create_simple_file('lib/test.rb')])

    assert tree.key?('lib')
    assert tree['lib'].key?('test.rb')
    assert_equal 'lib/test.rb', tree['lib']['test.rb'][:file].filename
  end

  def test_build_tree_nested_files # rubocop:disable Metrics/AbcSize, Minitest/MultipleAssertions
    file1 = create_simple_file('lib/models/user.rb')
    file2 = create_simple_file('lib/controllers/api.rb')
    tree = @reporter.send(:build_tree, [file1, file2])

    assert tree.key?('lib')
    assert tree['lib'].key?('models')
    assert tree['lib'].key?('controllers')
    assert_equal 'lib/models/user.rb', tree['lib']['models']['user.rb'][:file].filename
    assert_equal 'lib/controllers/api.rb', tree['lib']['controllers']['api.rb'][:file].filename
  end

  def test_calculate_max_width_single_level
    file = create_simple_file('test.rb')
    tree = { 'test.rb' => { file: file } }
    width = @reporter.send(:calculate_max_width, tree, 0)

    assert_equal 7, width
  end

  def test_calculate_max_width_nested
    file = create_simple_file('lib/models/user.rb')
    tree = {
      'lib' => {
        'models' => {
          'user.rb' => { file: file }
        }
      }
    }
    width = @reporter.send(:calculate_max_width, tree, 0)

    assert_equal 9, width
  end

  def test_collect_files_single_file
    file = create_simple_file('test.rb')
    node = { 'test.rb' => { file: file } }
    files = @reporter.send(:collect_files, node)

    assert_equal 1, files.length
    assert_equal file, files.first
  end

  def test_collect_files_nested # rubocop:disable Metrics/MethodLength
    file1 = create_simple_file('lib/test1.rb')
    file2 = create_simple_file('lib/test2.rb')
    node = {
      'lib' => {
        'test1.rb' => { file: file1 },
        'test2.rb' => { file: file2 }
      }
    }
    files = @reporter.send(:collect_files, node)

    assert_equal 2, files.length
    assert_includes files, file1
    assert_includes files, file2
  end

  private

  def create_simple_file(filename)
    Struct.new(:filename).new(filename)
  end
end
