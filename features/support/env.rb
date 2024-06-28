# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::CoberturaFormatter]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.start do
  add_filter '/features/'
  add_filter '/test/'
  add_filter 'lib/nonnative/cucumber.rb'
  coverage_dir 'reports'
end

require 'nonnative'
