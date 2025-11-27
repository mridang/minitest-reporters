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

## Contributing

Contributions are welcome! If you find a bug or have suggestions for improvement, please open an issue or submit a pull request.

## License

Apache License 2.0 © 2025 Mridang Agarwalla
