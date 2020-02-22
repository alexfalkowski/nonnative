# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/features/'
end

require 'nonnative'
require 'rspec-benchmark'

World(RSpec::Benchmark::Matchers)
