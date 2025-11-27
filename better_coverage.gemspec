# frozen_string_literal: true

require_relative 'lib/minitest_plus/version'

Gem::Specification.new do |gemspec|
  gemspec.name = 'better_coverage'
  gemspec.version = MinitestPlus::VERSION
  gemspec.platform = Gem::Platform::RUBY
  gemspec.authors = ['Mridang Agarwalla']
  gemspec.email = ['mridang.agarwalla@gmail.com']
  gemspec.homepage = 'https://github.com/mridang/minitest-reporters'
  gemspec.summary = 'Jest-style coverage reporter for Minitest'
  gemspec.description = 'Minitest reporter displaying SimpleCov coverage in Jest/Istanbul format with directory tree'
  gemspec.license = 'Apache-2.0'
  gemspec.required_ruby_version = '>= 3.0'
  gemspec.metadata = { 'rubygems_mfa_required' => 'true' }

  gemspec.add_dependency 'minitest-reporters', '~> 1.5'
  gemspec.add_dependency 'simplecov', '~> 0.22'

  gemspec.files = Dir.chdir(File.expand_path(__dir__)) do
    `find lib README.md LICENSE.txt -type f -print0 2>/dev/null`.split("\x0").reject do |f|
      f.match(/\.gem\z/)
    end
  end
  gemspec.executables = []
  gemspec.require_paths = ['lib']
end
