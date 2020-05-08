# frozen_string_literal: true

Given('I configure nonnative programatically with servers') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |d|
      d.klass = Nonnative::TCPServer
      d.timeout = 1
      d.port = 12_323
    end

    config.server do |d|
      d.klass = Nonnative::TCPServer
      d.timeout = 1
      d.port = 12_324
    end
  end
end

Given('I configure nonnative through configuration with servers') do
  Nonnative.load_configuration('features/servers.yml')
end

When('I send a message with the tcp client to the servers') do
  @responses = []
  @responses << Nonnative::TCPClient.new(12_323).request('')
  @responses << Nonnative::TCPClient.new(12_324).request('')
end
