# frozen_string_literal: true

Given('I configure nonnative programatically with servers') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |d|
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 12_323
    end

    config.server do |d|
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 12_324
    end

    config.server do |d|
      d.klass = Nonnative::Features::HTTPServer
      d.timeout = 1
      d.port = 4567
    end

    config.server do |d|
      d.klass = Nonnative::Features::GRPCServer
      d.timeout = 1
      d.port = 9002
    end
  end
end

Given('I configure nonnative through configuration with servers') do
  Nonnative.load_configuration('features/servers.yml')
end

When('I send a message with the tcp client to the servers') do
  @responses = []
  @responses << Nonnative::Features::TCPClient.new(12_323).request('')
  @responses << Nonnative::Features::TCPClient.new(12_324).request('')
end

When('I send a message with the http client to the servers') do
  @response = Nonnative::Features::HTTPClient.new('http://localhost:4567').request
end

When('I send a message with the grpc client to the servers') do
  stub = Nonnative::Features::Greeter::Stub.new('localhost:9002', :this_channel_is_insecure)
  @response = stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!'))
end

When('I send a health request') do
  @response = Nonnative::Observability.new('http://localhost:4567').health
end

When('I send a metrics request') do
  @response = Nonnative::Observability.new('http://localhost:4567').metrics
end

Then('I should receive a http {string} response') do |response|
  expect(@response.code).to eq(200)
  expect(@response.body).to eq(response)
end

Then('I should receive a grpc {string} response') do |response|
  expect(@response.message).to eq(response)
end

Then('I should receive a successful health response') do
  expect(@response.code).to eq(200)
end

Then('I should receive a successful metrics response') do
  expect(@response.code).to eq(200)
end
