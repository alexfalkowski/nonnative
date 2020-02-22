# frozen_string_literal: true

Given('we configure nonnative programatically') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.definition do |d|
      d.process = 'features/support/bin/start 12_321'
      d.timeout = 5
      d.port = 12_321
      d.file = 'features/logs/12_321.log'
    end

    config.definition do |d|
      d.process = 'features/support/bin/start 12_322'
      d.timeout = 5
      d.port = 12_322
      d.file = 'features/logs/12_322.log'
    end
  end
end

Given('we start nonnative') do
  Nonnative.start
end

When('we send {string} with the echo client') do |message|
  @responses = []
  @responses << Nonnative::EchoClient.new(12_321).request(message)
  @responses << Nonnative::EchoClient.new(12_322).request(message)
end

Then('we should receive a {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
ensure
  Nonnative.stop
end
