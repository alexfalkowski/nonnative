# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/features/'
end

require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :startup

  config.definition do |d|
    d.process = 'features/support/bin/start 12_321'
    d.timeout = 0.5
    d.port = 12_321
    d.file = 'logs_12_321'
  end

  config.definition do |d|
    d.process = 'features/support/bin/start 12_322'
    d.timeout = 0.5
    d.port = 12_322
    d.file = 'logs_12_322'
  end
end
