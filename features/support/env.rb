# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/features/'
end

require 'nonnative'

Nonnative.configure do |config|
  config.process = 'features/support/bin/start'
  config.timeout = 0.5
  config.port = 12_321
end
