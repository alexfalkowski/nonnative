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

Given('I configure the system programmatically with a composed HTTP server') do
  configure_with_defaults(url: 'http://localhost:4567') do |config|
    add_server(config, name: 'http_server_1', klass: Nonnative::Features::ComposedHTTPServer, timeout: 1,
                       host: '127.0.0.1', ports: [4567], log: 'test/reports/composed_http_server.log')
  end
end

Given('I configure the system programmatically with an empty HTTP server') do
  configure_with_defaults(url: 'http://localhost:4567') do |config|
    add_server(config, name: 'http_server_1', klass: Nonnative::Features::EmptyHTTPServer, timeout: 1,
                       host: '127.0.0.1', ports: [4567], log: 'test/reports/empty_http_server.log')
  end
end

Given('I configure the system programmatically with a composed gRPC server') do
  configure_with_defaults do |config|
    add_server(config, name: 'grpc_server_1', klass: Nonnative::Features::ComposedGRPCServer, timeout: 1,
                       host: '127.0.0.1', ports: [9002], log: 'test/reports/composed_grpc_server.log')
  end
end

Given('I configure the system programmatically with an empty gRPC server') do
  configure_with_defaults do |config|
    add_server(config, name: 'grpc_server_1', klass: Nonnative::Features::EmptyGRPCServer, timeout: 1,
                       host: '127.0.0.1', ports: [9002], log: 'test/reports/empty_grpc_server.log')
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

Given('I configure the system programmatically with an unreachable HTTP proxy server') do
  configure_with_defaults(url: 'http://localhost:4570') do |config|
    add_server(config, name: 'unreachable_http_proxy_server', klass: Nonnative::Features::UnreachableHTTPProxyServer, timeout: 1,
                       host: '127.0.0.1', ports: [4570], log: 'test/reports/unreachable_http_proxy_server.log')
  end
end

Given('I configure the system programmatically with an unresponsive HTTP proxy server') do
  configure_with_defaults(url: 'http://localhost:4570') do |config|
    add_server(config, name: 'unresponsive_http_proxy_target', klass: Nonnative::Features::UnresponsiveTCPServer, timeout: 1,
                       host: '127.0.0.1', ports: [4571], log: 'test/reports/unresponsive_http_proxy_target.log')
    add_server(config, name: 'unresponsive_http_proxy_server', klass: Nonnative::Features::UnresponsiveHTTPProxyServer, timeout: 1,
                       host: '127.0.0.1', ports: [4570], log: 'test/reports/unresponsive_http_proxy_server.log')
  end
end

Given('I configure the system programmatically with a short-timeout HTTP proxy server') do
  configure_with_defaults(url: 'http://localhost:4570') do |config|
    add_server(config, name: 'unresponsive_http_proxy_target', klass: Nonnative::Features::UnresponsiveTCPServer, timeout: 1,
                       host: '127.0.0.1', ports: [4571], log: 'test/reports/unresponsive_http_proxy_target.log')
    add_server(config, name: 'unresponsive_http_proxy_server', klass: Nonnative::Features::ShortTimeoutHTTPProxyServer, timeout: 1,
                       host: '127.0.0.1', ports: [4570], log: 'test/reports/unresponsive_http_proxy_server.log')
  end
end

Given('I configure the system programmatically with an unresponsive health server') do
  configure_with_defaults(url: 'http://localhost:4572') do |config|
    add_server(config, name: 'unresponsive_health_server', klass: Nonnative::Features::UnresponsiveTCPServer, timeout: 1,
                       host: '127.0.0.1', ports: [4572], log: 'test/reports/unresponsive_health_server.log')
  end
end

When('I send a message with the tcp client to the servers') do
  @responses = %w[tcp_server_1 tcp_server_2].map { |name| tcp_client_for_server(name).request('') }
end

When('I send a message with the HTTP client to the servers') do
  @responses = %w[http_server_1 http_server_2].flat_map do |name|
    client = http_client_for_server(name)

    [client.hello_get, client.hello_post, client.hello_put, client.hello_patch, client.hello_delete]
  end
end

When('I send a mounted message with the HTTP client to the server') do
  @responses = [http_client_for_server('http_server_1').mounted_get]
end

When('I send a root message with the HTTP client to the server') do
  @responses = [http_client_for_server('http_server_1').hello_get]
end

When('I send a message with the gRPC client to the servers') do
  @responses = %w[grpc_server_1 grpc_server_2].map do |name|
    grpc_client_for_server(name).say_hello(greeter_request)
  end
end

When('I send a message with the gRPC client to the server') do
  @responses = [grpc_client_for_server('grpc_server_1').say_hello(greeter_request)]
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

When('I send a not found PATCH message with the HTTP client to the servers') do
  @response = http_client_for_server('http_server_1').patch_not_found
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

When('I send hop-by-hop request headers to the local HTTP proxy server') do
  @response = http_client_for_server('local_http_proxy_server').inspect_request_with_hop_by_hop_headers
end

When('I send a raw UTF-8 path to the local HTTP proxy server') do
  @raw_response = http_client_for_server('local_http_proxy_server').raw_path('/café')
end

When('I send a raw bracket path to the local HTTP proxy server') do
  @raw_response = http_client_for_server('local_http_proxy_server').raw_path('/a[b]')
end

When('I request response metadata through the local HTTP proxy server') do
  @response = http_client_for_server('local_http_proxy_server').response_metadata
end

When('I request response metadata with an OPTIONS request through the local HTTP proxy server') do
  @response = http_client_for_server('local_http_proxy_server').response_metadata_options
end

When('I send a HEAD request to the local HTTP proxy server') do
  @response = http_client_for_server('local_http_proxy_server').inspect_head
end

When('I send a request to the unreachable HTTP proxy server') do
  @response = RestClient::Request.execute(method: :get, url: 'http://localhost:4570/hello', open_timeout: 1, read_timeout: 1)
rescue RestClient::ExceptionWithResponse => e
  @response = e.response
end

When('I send a request to the unresponsive HTTP proxy server') do
  @response = RestClient::Request.execute(method: :get, url: 'http://localhost:4570/hello', open_timeout: 3, read_timeout: 3)
rescue RestClient::ExceptionWithResponse => e
  @response = e.response
end

When('I send a request with a short client timeout to the unresponsive HTTP proxy server') do
  @response = RestClient::Request.execute(method: :get, url: 'http://localhost:4570/hello', open_timeout: 0.5, read_timeout: 0.5)
rescue RestClient::ExceptionWithResponse => e
  @response = e.response
end

When('I request health from the unresponsive health server with a {float} second read timeout') do |duration|
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  begin
    Nonnative.observability.health(read_timeout: duration, open_timeout: duration)
  rescue StandardError => e
    @error = e
  end

  @elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
end

When('I send a HEAD message with the HTTP client to the server') do
  @response = http_client_for_server('http_server_1').hello_head
end

When('I send an OPTIONS message with the HTTP client to the server') do
  @response = http_client_for_server('http_server_1').hello_options
end

Then('I should receive an HTTP {string} response') do |response|
  @responses.each do |r|
    expect(r.code).to eq(200)
    expect(r.body).to eq(response.to_json)
  end
end

Then('I should receive an HTTP response with an empty body and status {int}') do |status|
  expect(@response.code).to eq(status)
  expect(@response.body).to be_nil.or eq('')
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

Then('I should receive a successful response from the local HTTP proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(200)
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

Then('the local HTTP proxy server should not forward hop-by-hop request headers') do
  body = JSON.parse(@response.body)

  expect(@response.code).to eq(200)
  expect(body.values_at('connection', 'connection_scoped', 'keep_alive', 'te', 'trailer', 'transfer_encoding', 'upgrade')).to all(be_nil)
end

Then('the local HTTP proxy server should forward the raw UTF-8 path') do
  expect(@raw_response).to start_with('HTTP/1.1 200')
  expect(@raw_response).to include('Café'.b)
end

Then('the local HTTP proxy server should forward the raw bracket path') do
  expect(@raw_response).to start_with('HTTP/1.1 200')
  expect(@raw_response).to include('brackets')
end

Then('I should receive preserved response metadata from the local HTTP proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(201)
  expect(@response.body).to eq('upstream response body')
  expect(@response.headers[:content_type]).to eq('application/problem+json')
  expect(@response.headers[:etag]).to eq('"response-v1"')
  expect(@response.headers[:x_end_to_end]).to eq('preserved')
  expect(@response.headers[:www_authenticate]).to eq('Bearer realm="response-test"')
  expect(@response.headers[:proxy_authenticate]).to be_nil
  expect(@response.headers[:x_upstream_only]).to be_nil
end

Then('I should receive a clean bad gateway response') do
  expect(@response.code).to eq(502)
  expect(@response.body).not_to include('Errno::ECONNREFUSED')
end

Then('I should receive a clean gateway timeout response') do
  expect(@response.code).to eq(504)
end

Then('requesting health should raise a timeout error within {float} seconds') do |bound|
  expect(@error).to be_a(Timeout::Error)
  expect(@elapsed).to be < bound
end

Then('I should find the server runner {string}') do |name|
  expect(@server_runner.name).to eq(name)
end
