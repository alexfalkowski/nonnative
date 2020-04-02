# frozen_string_literal: true

Given('I configure nonnative programatically with processes') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.process do |d|
      d.command = 'features/support/bin/start 12_321'
      d.timeout = 5
      d.port = 12_321
      d.file = 'features/logs/12_321.log'
    end

    config.process do |d|
      d.command = 'features/support/bin/start 12_322'
      d.timeout = 5
      d.port = 12_322
      d.file = 'features/logs/12_322.log'
    end
  end
end

Given('I start nonnative') do
  Nonnative.start
end

When('I send {string} with the echo client') do |message|
  @responses = []
  @responses << Nonnative::EchoClient.new(12_321).request(message)
  @responses << Nonnative::EchoClient.new(12_322).request(message)
end

Then('I should receive a {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
ensure
  Nonnative.stop
end
