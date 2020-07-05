# frozen_string_literal: true

Given('I configure nonnative programatically with servers') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |d|
      d.name = 'tcp_server_1'
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 12_323
    end

    config.server do |d|
      d.name = 'tcp_server_2'
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 12_324
    end

    config.server do |d|
      d.name = 'http_server_1'
      d.klass = Nonnative::Features::HTTPServer
      d.timeout = 1
      d.port = 4567
      d.proxy.type = 'chaos'
      d.proxy.port = 20_001
    end

    config.server do |d|
      d.name = 'http_server_2'
      d.klass = Nonnative::Features::HTTPServer
      d.timeout = 1
      d.port = 4568
      d.proxy.type = 'chaos'
      d.proxy.port = 20_002
    end

    config.server do |d|
      d.name = 'grpc_server_1'
      d.klass = Nonnative::Features::GRPCServer
      d.timeout = 1
      d.port = 9002
      d.proxy.type = 'chaos'
      d.proxy.port = 20_003
    end

    config.server do |d|
      d.name = 'grpc_server_2'
      d.klass = Nonnative::Features::GRPCServer
      d.timeout = 1
      d.port = 9003
      d.proxy.type = 'chaos'
      d.proxy.port = 20_004
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
  @responses = []
  urls = ['http://localhost:4567', 'http://localhost:4568']

  urls.each do |u|
    client = Nonnative::Features::HTTPClient.new(u)

    @responses << client.hello_get
    @responses << client.hello_post
    @responses << client.hello_put
    @responses << client.hello_delete
  end
end

When('I send a message with the grpc client to the servers') do
  @responses = []
  urls = ['localhost:9002', 'localhost:9003']

  urls.each do |u|
    stub = Nonnative::Features::Greeter::Stub.new(u, :this_channel_is_insecure)

    @responses << stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!'))
  end

  stub = Nonnative::Features::Greeter::Stub.new('localhost:9002', :this_channel_is_insecure)
  @response = stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!'))
end

When('I send a health request') do
  @response = Nonnative::Observability.new('http://localhost:4567').health
end

When('I send a metrics request') do
  @response = Nonnative::Observability.new('http://localhost:4567').metrics
end

When('I send a not found message with the http client to the servers') do
  @response = Nonnative::Features::HTTPClient.new('http://localhost:4567').not_found
end

When('I set the proxy for server {string} to {string}') do |name, operation|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.send(operation)
end

Then('I should receive a http {string} response') do |response|
  @responses.each do |r|
    expect(r.code).to eq(200)
    expect(r.body).to eq(response.to_json)
  end
end

Then('I should receive a grpc {string} response') do |response|
  @responses.each do |r|
    expect(r.message).to eq(response)
  end
end

Then('I should receive a successful health response') do
  expect(@response.code).to eq(200)
end

Then('I should receive a successful metrics response') do
  expect(@response.code).to eq(200)
end

Then('I should receive a http not found response') do
  expect(@response.code).to eq(404)
end

Then('I should receive a connection error for metrics response') do
  expect { Nonnative::Observability.new('http://localhost:4567').metrics }.to raise_error(Errno::ECONNRESET)
end

Then('I should reset the proxy for server {string}') do |name|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.reset
end
