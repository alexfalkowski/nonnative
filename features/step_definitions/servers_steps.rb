# frozen_string_literal: true

Given('I configure nonnative programatically with servers') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |s|
      s.name = 'tcp_server_1'
      s.klass = Nonnative::Features::TCPServer
      s.timeout = 1
      s.port = 12_323
      s.log = 'features/logs/tcp_server_1.log'
    end

    config.server do |s|
      s.name = 'tcp_server_2'
      s.klass = Nonnative::Features::TCPServer
      s.timeout = 1
      s.port = 12_324
      s.log = 'features/logs/tcp_server_2.log'
    end

    config.server do |s|
      s.name = 'http_server_1'
      s.klass = Nonnative::Features::HTTPServer
      s.timeout = 1
      s.port = 4567
      s.log = 'features/logs/http_server_1.log'
      s.proxy = {
        type: 'fault_injection',
        port: 20_001,
        log: 'features/logs/proxy_http_server_1.log',
        options: {
          delay: 10
        }
      }
    end

    config.server do |s|
      s.name = 'http_server_2'
      s.klass = Nonnative::Features::HTTPServer
      s.timeout = 1
      s.port = 4568
      s.log = 'features/logs/http_server_2.log'
      s.proxy = {
        type: 'fault_injection',
        port: 20_002,
        log: 'features/logs/proxy_http_server_2.log',
        options: {
          delay: 2
        }
      }
    end

    config.server do |s|
      s.name = 'grpc_server_1'
      s.klass = Nonnative::Features::GRPCServer
      s.timeout = 1
      s.port = 9002
      s.log = 'features/logs/grpc_server_1.log'
      s.proxy = {
        type: 'fault_injection',
        port: 20_003,
        log: 'features/logs/proxy_grpc_server_1.log',
        options: {
          delay: 5
        }
      }
    end

    config.server do |s|
      s.name = 'grpc_server_2'
      s.klass = Nonnative::Features::GRPCServer
      s.timeout = 1
      s.port = 9003
      s.log = 'features/logs/grpc_server_2.log'
      s.proxy = {
        type: 'fault_injection',
        port: 20_004,
        log: 'features/logs/proxy_grpc_server_2.log',
        options: {
          delay: 7
        }
      }
    end
  end
end

Given('I configure nonnative through configuration with servers') do
  Nonnative.load_configuration('features/configs/servers.yml')
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

Then('I should receive a connection error for metrics response with HTTP') do
  expect { Nonnative::Observability.new('http://localhost:4567').metrics }.to raise_error(StandardError)
end

Then('I should receive a delay error for hello response with HTTP') do
  call = -> { Nonnative::Features::HTTPClient.new('http://localhost:4567').hello_get }
  expect(call).to raise_error(RestClient::Exceptions::ReadTimeout)
end

Then('I should receive a invalid data error for hello response with HTTP') do
  call = -> { Nonnative::Features::HTTPClient.new('http://localhost:4567').hello_get }
  expect(call).to raise_error(Net::HTTPBadResponse)
end

Then('I should receive a connection error for being greeted with gRPC') do
  stub = Nonnative::Features::Greeter::Stub.new('localhost:9002', :this_channel_is_insecure)
  call = -> { stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!')) }

  expect(call).to raise_error(GRPC::Unavailable)
end

Then('I should receive a delay error for being greeted with gRPC') do
  stub = Nonnative::Features::Greeter::Stub.new('localhost:9002', :this_channel_is_insecure, timeout: 1)
  call = -> { stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!')) }

  expect(call).to raise_error(GRPC::DeadlineExceeded)
end

Then('I should receive a invalid data error for being greeted with gRPC') do
  stub = Nonnative::Features::Greeter::Stub.new('localhost:9002', :this_channel_is_insecure)
  call = -> { stub.say_hello(Nonnative::Features::HelloRequest.new(name: 'Hello World!')) }

  expect(call).to raise_error(StandardError)
end
