# frozen_string_literal: true

Given('I configure nonnative programatically with processes') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.process do |d|
      d.name = 'start_1'
      d.command = 'features/support/bin/start 12_321'
      d.timeout = 5
      d.port = 12_321
      d.log = 'features/logs/12_321.log'
      d.signal = 'INT'
    end

    config.process do |d|
      d.name = 'start_2'
      d.command = 'features/support/bin/start 12_322'
      d.timeout = 5
      d.port = 12_322
      d.log = 'features/logs/12_322.log'
      d.signal = 'TERM'
    end
  end
end

Given('I start nonnative') do
  Nonnative.start
end

When('I send {string} with the tcp client to the processes') do |message|
  @responses = []
  @responses << Nonnative::Features::TCPClient.new(12_321).request(message)
  @responses << Nonnative::Features::TCPClient.new(12_322).request(message)
end

Then('I should receive a tcp {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
end
