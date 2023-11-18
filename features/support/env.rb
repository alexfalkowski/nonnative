# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.start do
  add_filter '/features/'
  add_filter '/test/'
  coverage_dir 'reports'
end

require 'nonnative'
