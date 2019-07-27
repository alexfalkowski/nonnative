# frozen_string_literal: true

require 'nonnative'

Nonnative.configure do |config|
  config.process = 'features/support/bin/start'
  config.wait = 0.5
end
