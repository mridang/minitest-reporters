# frozen_string_literal: true

require 'minitest/reporters'

module MinitestPlus
  # Jest-style coverage reporter for Minitest
  # Displays SimpleCov coverage data in Jest's console format
  class BetterCoverage < Minitest::Reporters::BaseReporter # rubocop:disable Metrics/ClassLength
    NAME_COL = 4
    PCT_COLS = 7
    MISSING_COL = 17
    TAB_SIZE = 1
    DELIM = ' | '

    def initialize(options = {})
      super({})
      @max_cols = options[:max_cols] || 80
      @skip_empty = options[:skip_empty] || false
      @skip_full = options[:skip_full] || false
    end

    def report
      super
      return unless defined?(SimpleCov)

      result = SimpleCov.result
      return unless result

      print_coverage_table(result)
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def print_coverage_table(result)
      files = result.files.sort_by(&:filename)
      return if files.empty?

      tree = build_tree(files)
      name_width = [NAME_COL, calculate_max_width(tree, 0)].max
      missing_width = [MISSING_COL, files.map { |f| uncovered_lines(f).length }.max].max

      if @max_cols.positive?
        pct_cols = DELIM.length + (4 * (PCT_COLS + DELIM.length)) + 2
        max_remaining = @max_cols - (pct_cols + MISSING_COL)

        if name_width > max_remaining
          name_width = max_remaining
          missing_width = MISSING_COL
        elsif name_width < max_remaining
          max_remaining = @max_cols - (name_width + pct_cols)
          missing_width = max_remaining if missing_width > max_remaining
        end
      end

      puts
      puts make_line(name_width, missing_width)
      puts table_header(name_width, missing_width)
      puts make_line(name_width, missing_width)
      print_tree(tree, name_width, missing_width, 0)

      total_pct = result.covered_percent
      summary_row = summary_line(total_pct, name_width, missing_width)
      puts make_line(name_width, missing_width)
      puts summary_row
      puts make_line(name_width, missing_width)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def build_tree(files) # rubocop:disable Metrics/MethodLength
      tree = {}

      files.each do |file|
        path = relative_path(file.filename)
        parts = path.split('/')

        current = tree
        parts.each_with_index do |part, idx|
          if idx == parts.length - 1
            current[part] = { file: file }
          else
            current[part] ||= {}
            current = current[part]
          end
        end
      end

      tree
    end

    def calculate_max_width(tree, depth)
      max = 0
      tree.each do |name, node|
        width = (TAB_SIZE * depth) + name.length
        max = width if width > max

        next unless node[:file].nil?

        child_max = calculate_max_width(node, depth + 1)
        max = child_max if child_max > max
      end
      max
    end

    def print_tree(tree, name_width, missing_width, depth) # rubocop:disable Metrics/MethodLength
      tree.keys.sort.each do |name|
        node = tree[name]

        if node[:file]
          row = file_row(node[:file], name, name_width, missing_width, depth)
          puts row unless row.empty?
        else
          row = dir_row(name, node, name_width, missing_width, depth)
          puts row unless row.empty?
          print_tree(node, name_width, missing_width, depth + 1)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def dir_row(name, node, name_width, missing_width, depth)
      files = collect_files(node)
      return '' if files.empty?
      return '' if @skip_empty && files.all? { |f| f.lines.empty? }

      total_covered = files.sum { |f| f.covered_lines.size }
      total_lines = files.sum { |f| f.lines.reject(&:skipped?).size }
      pct = total_lines.positive? ? (total_covered.to_f / total_lines * 100).round(2) : 0.0

      return '' if @skip_full && pct == 100.0 # rubocop:disable Lint/FloatComparison

      elements = [
        colorize_by_coverage(fill(name, name_width, tabs: depth), pct),
        colorize_by_coverage(fill(pct, PCT_COLS, right: true), pct),
        colorize_by_coverage(fill('100', PCT_COLS + 1, right: true), 100),
        colorize_by_coverage(fill('100', PCT_COLS, right: true), 100),
        colorize_by_coverage(fill(pct, PCT_COLS, right: true), pct),
        fill('', missing_width)
      ]

      "#{elements.join(DELIM)} "
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def collect_files(node)
      files = []
      node.each_value do |value|
        if value[:file]
          files << value[:file]
        else
          files.concat(collect_files(value))
        end
      end
      files
    end

    def file_row(file, name, name_width, missing_width, depth) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return '' if @skip_empty && file.lines.empty?

      pct_lines = file.covered_percent.round(2)
      return '' if @skip_full && pct_lines == 100.0 # rubocop:disable Lint/FloatComparison

      elements = [
        colorize_by_coverage(fill(name, name_width, tabs: depth), pct_lines),
        colorize_by_coverage(fill(pct_lines, PCT_COLS, right: true), pct_lines),
        colorize_by_coverage(fill('100', PCT_COLS + 1, right: true), 100),
        colorize_by_coverage(fill('100', PCT_COLS, right: true), 100),
        colorize_by_coverage(fill(pct_lines, PCT_COLS, right: true), pct_lines),
        colorize_uncovered(fill(uncovered_lines(file), missing_width), pct_lines)
      ]

      "#{elements.join(DELIM)} "
    end

    def summary_line(total_pct, name_width, missing_width)
      total_pct_rounded = total_pct.round(2)

      elements = [
        colorize_by_coverage(fill('All files', name_width), total_pct),
        colorize_by_coverage(fill(total_pct_rounded, PCT_COLS, right: true), total_pct),
        colorize_by_coverage(fill('100', PCT_COLS + 1, right: true), 100),
        colorize_by_coverage(fill('100', PCT_COLS, right: true), 100),
        colorize_by_coverage(fill(total_pct_rounded, PCT_COLS, right: true), total_pct),
        fill('', missing_width)
      ]

      "#{elements.join(DELIM)} "
    end

    def relative_path(filename)
      filename.sub("#{SimpleCov.root}/", '')
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def uncovered_lines(file)
      covered_lines = file.lines.reject(&:skipped?).map do |line|
        [line.line_number, line.covered? || line.never?]
      end

      new_range = true
      ranges = covered_lines.each_with_object([]) do |(line, hit), acum|
        if hit
          new_range = true
        elsif new_range
          acum.push([line])
          new_range = false
        else
          acum.last[1] = line
        end
      end

      ranges.map do |range|
        range.length == 1 ? range[0].to_s : "#{range[0]}-#{range[1]}"
      end.join(',')
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def fill(text, width, right: false, tabs: 0) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      text = text.to_s
      leading_spaces = tabs * TAB_SIZE
      remaining = width - leading_spaces
      leader = ' ' * leading_spaces

      return leader if remaining <= 0

      if remaining >= text.length
        fill_str = ' ' * (remaining - text.length)
        leader + (right ? fill_str + text : text + fill_str)
      else
        fill_str = '...'
        length = remaining - fill_str.length
        text = text[-length..] || text
        leader + fill_str + text
      end
    end

    def make_line(name_width, missing_width)
      elements = [
        '-' * name_width,
        '-' * PCT_COLS,
        '-' * (PCT_COLS + 1),
        '-' * PCT_COLS,
        '-' * PCT_COLS,
        '-' * missing_width
      ]
      "#{elements.join(DELIM.gsub(' ', '-'))}-"
    end

    def table_header(name_width, missing_width)
      elements = [
        fill('File', name_width),
        fill('% Stmts', PCT_COLS, right: true),
        fill('% Branch', PCT_COLS + 1, right: true),
        fill('% Funcs', PCT_COLS, right: true),
        fill('% Lines', PCT_COLS, right: true),
        fill('Uncovered Line #s', missing_width)
      ]
      "#{elements.join(DELIM)} "
    end

    def colorize_by_coverage(text, pct)
      case pct
      when 80..100 then green(text)
      when 50...80 then yellow(text)
      else red(text)
      end
    end

    def colorize_uncovered(text, pct)
      pct == 100 ? text : red(text)
    end

    def green(text)
      "\e[32m#{text}\e[0m"
    end

    def yellow(text)
      "\e[33m#{text}\e[0m"
    end

    def red(text)
      "\e[31m#{text}\e[0m"
    end
  end
end
