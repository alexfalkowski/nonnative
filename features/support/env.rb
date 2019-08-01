# frozen_string_literal: true

require 'nonnative'

Nonnative.configure do |config|
  config.process = 'features/support/bin/start'
  config.timeout = 0.5
  config.port = 12_321
end
