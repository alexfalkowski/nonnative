# frozen_string_literal: true

Given('we configure nonnative to startup') do
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
end

When('we send {string} with the echo client') do |message|
  @responses = []
  @responses << Nonnative::EchoClient.new(12_321).request(message)
  @responses << Nonnative::EchoClient.new(12_322).request(message)
end

Then('we should receive a {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
end
