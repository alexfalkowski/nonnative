# frozen_string_literal: true

Given('I configure the system programatically with servers') do
  Nonnative.configure do |config|
    config.server do |s|
      s.name = 'tcp_server_1'
      s.klass = Nonnative::Features::TCPServer
      s.timeout = 1
      s.port = 12_323
      s.log = 'reports/tcp_server_1.log'
    end

    config.server do |s|
      s.name = 'tcp_server_2'
      s.klass = Nonnative::Features::TCPServer
      s.timeout = 1
      s.port = 12_324
      s.log = 'reports/tcp_server_2.log'
    end

    config.server do |s|
      s.name = 'http_server_1'
      s.klass = Nonnative::Features::HTTPServer
      s.timeout = 1
      s.host = '127.0.0.1'
      s.port = 4567
      s.log = 'reports/http_server_1.log'
    end

    config.server do |s|
      s.name = 'http_server_2'
      s.klass = Nonnative::Features::HTTPServer
      s.timeout = 1
      s.port = 4568
      s.log = 'reports/http_server_2.log'
    end

    config.server do |s|
      s.name = 'grpc_server_1'
      s.klass = Nonnative::Features::GRPCServer
      s.timeout = 1
      s.port = 9002
      s.log = 'reports/grpc_server_1.log'
    end

    config.server do |s|
      s.name = 'grpc_server_2'
      s.klass = Nonnative::Features::GRPCServer
      s.timeout = 1
      s.port = 9003
      s.log = 'reports/grpc_server_2.log'
    end
  end
end

Given('I configure the system through configuration with servers') do
  Nonnative.configure do |config|
    config.load_file('features/configs/servers.yml')
  end
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
    stub = Nonnative::Features::GreeterService::Stub.new(u, :this_channel_is_insecure, channel_args: Nonnative::Header.grpc_user_agent('test 1.0'))

    @responses << stub.say_hello(Nonnative::Features::SayHelloRequest.new(name: 'Hello World!'))
  end
end

When('I send a {string} request') do |name|
  @response = Nonnative::Observability.new('http://localhost:4567').send(name, { headers: { content_type: :json, accept: :json } })
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

Then('I should receive a successful {string} response') do |_|
  expect(@response.code).to eq(200)
end

Then('I should receive a http not found response') do
  expect(@response.code).to eq(404)
end

Then('I should receive a connection error for metrics response with HTTP') do
  expect { Nonnative::Observability.new('http://localhost:4567').metrics }.to raise_error(StandardError)
end

Then('I should receive a delay error for hello response with HTTP') do
  expect { Nonnative::Features::HTTPClient.new('http://localhost:4567').hello_get }.to raise_error(RestClient::Exceptions::ReadTimeout)
end

Then('I should receive a invalid data error for hello response with HTTP') do
  expect { Nonnative::Features::HTTPClient.new('http://localhost:4567').hello_get }.to raise_error(Net::HTTPBadResponse)
end

Then('I should receive a connection error for being greeted with gRPC') do
  stub = Nonnative::Features::GreeterService::Stub.new('localhost:9002', :this_channel_is_insecure)
  expect { stub.say_hello(Nonnative::Features::SayHelloRequest.new(name: 'Hello World!')) }.to raise_error(GRPC::Unavailable)
end

Then('I should receive a delay error for being greeted with gRPC') do
  stub = Nonnative::Features::GreeterService::Stub.new('localhost:9002', :this_channel_is_insecure, timeout: 1)
  expect { stub.say_hello(Nonnative::Features::SayHelloRequest.new(name: 'Hello World!')) }.to raise_error(GRPC::DeadlineExceeded)
end

Then('I should receive a invalid data error for being greeted with gRPC') do
  stub = Nonnative::Features::GreeterService::Stub.new('localhost:9002', :this_channel_is_insecure)
  expect { stub.say_hello(Nonnative::Features::SayHelloRequest.new(name: 'Hello World!')) }.to raise_error(StandardError)
end
