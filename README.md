# better_coverage

**better_coverage** is a Minitest reporter that displays SimpleCov coverage results in Jest/Istanbul's console format with a directory tree structure.

##### Why?

Using better_coverage lets you see coverage in Jest's familiar table format right in your terminal. The reporter organizes files into a directory tree, shows uncovered line ranges (e.g., `5-12,18`), and applies the same color coding as Jest so your Ruby coverage reports look exactly like your JavaScript ones.

## Usage

Add the gem to your `Gemfile`:

```ruby
gem 'better_coverage'
```

Then configure in your `test/test_helper.rb`:

```ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'better_coverage'

Minitest::Reporters.use! [
  MinitestPlus::BetterCoverage.new
]
```

Run your tests:

```bash
bundle exec rake test
```

#### Options

```ruby
MinitestPlus::BetterCoverage.new(
  max_cols: 120,     # Terminal width (default: 80)
  skip_empty: true,  # Skip files with no lines (default: false)
  skip_full: true    # Skip 100% covered files (default: false)
)
```

## BetterJUnit

**BetterJUnit** is a Minitest reporter that aggregates **all** test suites into a single JUnit XML file.

##### Why?

The built-in `Minitest::Reporters::JUnitReporter` writes one XML file per test class (e.g. `TEST-CalculatorTest.xml`, `TEST-StringTest.xml`, ...). Most CI test-result consumers — GitHub Actions test annotators, Buildkite test analytics, CircleCI insights, etc. — expect a **single** combined artefact. `BetterJUnit` emits exactly that: one `<testsuites>` document containing every `<testsuite>`, with the same field set as the upstream reporter (so it stays interoperable with every standard JUnit consumer).

In your `test/test_helper.rb`:

```ruby
require 'minitest/reporters'
require 'better_junit'

Minitest::Reporters.use! [
  MinitestPlus::BetterJUnit.new
]
```

The combined report is written to `test/reports/junit.xml` by default.

#### Options

```ruby
MinitestPlus::BetterJUnit.new(
  path: 'build/reports/junit.xml',  # Output file path (default: 'test/reports/junit.xml')
  base_path: Dir.pwd,               # Base for relative file paths in XML (default: Dir.pwd)
  include_timestamp: true           # Add ISO8601 timestamp per suite (default: false)
)
```

The `path` option accepts any path — nested directories are created automatically:

```ruby
MinitestPlus::BetterJUnit.new(path: 'out/deeply/nested/results/my-custom-junit.xml')
```

#### Sample output

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="CalculatorTest" filepath="test/calculator_test.rb" skipped="0" failures="0" errors="0" tests="2" assertions="2" time="0.000021">
    <testcase name="test_addition" lineno="6" classname="CalculatorTest" assertions="1" time="0.000018" file="test/calculator_test.rb"/>
    <testcase name="test_subtraction" lineno="10" classname="CalculatorTest" assertions="1" time="0.000003" file="test/calculator_test.rb"/>
  </testsuite>
  <testsuite name="StringTest" filepath="test/string_test.rb" skipped="0" failures="0" errors="0" tests="2" assertions="2" time="0.000010">
    <testcase name="test_reverse" lineno="10" classname="StringTest" assertions="1" time="0.000007" file="test/string_test.rb"/>
    <testcase name="test_upcase" lineno="6" classname="StringTest" assertions="1" time="0.000003" file="test/string_test.rb"/>
  </testsuite>
</testsuites>
```

## Contributing

Contributions are welcome! If you find a bug or have suggestions for improvement, please open an issue or submit a pull request.

## License

Apache License 2.0 © 2025 Mridang Agarwalla
