# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'rbconfig'

formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::CoberturaFormatter]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.command_name(ENV.fetch('COVERAGE_NAME', 'Features'))
SimpleCov.start do
  add_filter '/features/'
  add_filter '/test/'
  add_filter 'lib/nonnative/cucumber.rb'
  coverage_dir 'test/reports'
end

require 'nonnative'
