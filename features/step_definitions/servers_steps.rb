# frozen_string_literal: true

Given('I configure the system programmatically with servers') do
  Nonnative::Features::Service.health_body = ''
  Nonnative::Features::Service.health_status = 200

  configure_with_defaults do |config|
    add_server(config, name: 'tcp_server_1', klass: Nonnative::Features::TCPServer, timeout: 1, ports: [12_323], log: 'test/reports/tcp_server_1.log')
    add_server(config, name: 'tcp_server_2', klass: Nonnative::Features::TCPServer, timeout: 1, ports: [12_324], log: 'test/reports/tcp_server_2.log')
    add_server(
      config,
      name: 'http_server_1',
      klass: Nonnative::Features::HTTPServer,
      timeout: 1,
      host: '127.0.0.1',
      ports: [4567],
      log: 'test/reports/http_server_1.log'
    )
    add_server(config, name: 'http_server_2', klass: Nonnative::Features::HTTPServer, timeout: 1, ports: [4568],
                       log: 'test/reports/http_server_2.log')
    add_server(config, name: 'grpc_server_1', klass: Nonnative::Features::GRPCServer, timeout: 1, ports: [9002],
                       log: 'test/reports/grpc_server_1.log')
    add_server(config, name: 'grpc_server_2', klass: Nonnative::Features::GRPCServer, timeout: 1, ports: [9003],
                       log: 'test/reports/grpc_server_2.log')
  end
end

Given('I configure the system through configuration with servers') do
  load_configuration('features/configs/servers.yml')
end

Given('I configure the system programmatically with a local HTTP proxy server') do
  configure_with_defaults(url: 'http://localhost:4570') do |config|
    add_server(config, name: 'http_proxy_target', klass: Nonnative::Features::HTTPServer, timeout: 1, host: '127.0.0.1', ports: [4571],
                       log: 'test/reports/http_proxy_target.log')
    add_server(config, name: 'local_http_proxy_server', klass: Nonnative::Features::LocalHTTPProxyServer, timeout: 1, host: '127.0.0.1',
                       ports: [4570], log: 'test/reports/local_http_proxy_server.log')
  end
end

When('I send a message with the tcp client to the servers') do
  @responses = %w[tcp_server_1 tcp_server_2].map { |name| tcp_client_for_server(name).request('') }
end

When('I send a message with the HTTP client to the servers') do
  @responses = %w[http_server_1 http_server_2].flat_map do |name|
    client = http_client_for_server(name)

    [client.hello_get, client.hello_post, client.hello_put, client.hello_delete]
  end
end

When('I send a message with the gRPC client to the servers') do
  @responses = %w[grpc_server_1 grpc_server_2].map do |name|
    grpc_client_for_server(name).say_hello(greeter_request)
  end
end

When('I send a {string} request') do |name|
  @response = observability_request(name)
end

When('the health endpoint reports service unavailable') do
  Nonnative::Features::Service.health_body = "http: service unavailable\n"
  Nonnative::Features::Service.health_status = 503
end

When('I send a not found message with the HTTP client to the servers') do
  @response = http_client_for_server('http_server_1').not_found
end

When('I look up the server runner {string}') do |name|
  @server_runner = Nonnative.pool.server_by_name(name)
end

When('I register a custom proxy kind') do
  @previous_custom_proxy = Nonnative.proxies['custom']
  Nonnative.proxies['custom'] = Nonnative::Features::CustomProxy
end

When('I try to resolve proxy kind {string}') do |kind|
  capture_result(:@proxy_result, :@proxy_error) { Nonnative.proxy(kind) }
end

Then('the custom proxy kind should resolve to the custom proxy') do
  actual = Nonnative.proxy('custom')
  Nonnative.proxies.delete('custom')
  Nonnative.proxies['custom'] = @previous_custom_proxy if @previous_custom_proxy

  expect(actual).to eq(Nonnative::Features::CustomProxy)
end

Then('resolving the proxy kind should fail with an argument error containing {string}') do |message|
  expect(@proxy_error).to be_a(ArgumentError)
  expect(@proxy_error.message).to include(message)
end

When('I send a successful message to the HTTP proxy server') do
  @response = RestClient::Resource.new("http://localhost:#{configured_server('http_proxy_server').port}").get
end

When('I send a not found message to the HTTP proxy server') do
  @response = http_client_for_server('http_proxy_server').hello_get
end

When('I send a {string} request with body {string} to the local HTTP proxy server') do |verb, body|
  @response = http_client_for_server('local_http_proxy_server').inspect_request(verb.downcase, body)
end

When('I send a {string} request with proxy credentials to the local HTTP proxy server') do |verb|
  @response = http_client_for_server('local_http_proxy_server').inspect_request_with_proxy_credentials(verb.downcase)
end

Then('I should receive an HTTP {string} response') do |response|
  @responses.each do |r|
    expect(r.code).to eq(200)
    expect(r.body).to eq(response.to_json)
  end
end

Then('I should receive a gRPC {string} response') do |response|
  @responses.each do |r|
    expect(r.message).to eq(response)
  end
end

Then('I should receive a successful {string} response') do |_|
  expect(@error).to be_nil
  expect(@response.code).to eq(200)
end

Then('I should receive an HTTP not found response') do
  expect(@error).to be_nil
  expect(@response.code).to eq(404)
end

Then('I should receive a successful response from the HTTP proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(200)
end

Then('I should receive a not found response from the HTTP proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(404)
end

Then('I should receive the {string} request details from the local HTTP proxy server') do |verb|
  body = JSON.parse(@response.body)

  expect(@error).to be_nil
  expect(@response.code).to eq(200)
  expect(body).to match_inspected_proxy_request(verb, 'Hello World!')
end

Then('I should receive request details without proxy credentials from the local HTTP proxy server') do
  body = JSON.parse(@response.body)

  expect(@error).to be_nil
  expect(@response.code).to eq(200)
  expect(body['authorization']).to eq('Bearer app-token')
  expect(body['proxy_authorization']).to be_nil
end

Then('I should find the server runner {string}') do |name|
  expect(@server_runner.name).to eq(name)
end
