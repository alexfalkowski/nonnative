# frozen_string_literal: true

Given('I configure the system programmatically with servers') do
  configure_servers_programmatically
end

Given('I configure the system through configuration with servers') do
  load_configuration('features/configs/servers.yml')
end

Given('I configure the system programmatically with a local http proxy server') do
  configure_local_http_proxy_server
end

When('I send a message with the tcp client to the servers') do
  @responses = %w[tcp_server_1 tcp_server_2].map { |name| tcp_client_for_server(name).request('') }
end

When('I send a message with the http client to the servers') do
  @responses = %w[http_server_1 http_server_2].flat_map do |name|
    client = http_client_for_server(name)

    [client.hello_get, client.hello_post, client.hello_put, client.hello_delete]
  end
end

When('I send a message with the grpc client to the servers') do
  @responses = %w[grpc_server_1 grpc_server_2].map do |name|
    grpc_client_for_server(name).say_hello(greeter_request)
  end
end

When('I send a {string} request') do |name|
  @response = observability_request(name)
end

When('I send a not found message with the http client to the servers') do
  @response = http_client_for_server('http_server_1').not_found
end

When('I try to find the proxy for server {string}') do |name|
  capture_result(:@server_runner, :@error) { Nonnative.pool.server_by_name(name) }
end

Then('I should get a proxy not found error') do
  expect(@error).to be_a_kind_of(Nonnative::NotFoundError)
end

When('I send a successful message to the http proxy server') do
  @response = RestClient::Resource.new("http://localhost:#{configured_server('http_proxy_server').port}").get
end

When('I send a not found message to the http proxy server') do
  @response = http_client_for_server('http_proxy_server').hello_get
end

When('I send a {string} request with body {string} to the local http proxy server') do |verb, body|
  @response = http_client_for_server('local_http_proxy_server').inspect_request(verb.downcase, body)
end

When('I request metrics over HTTP') do
  capture_result { Nonnative.observability.metrics }
end

When('I request hello over HTTP') do
  capture_result { http_client_for_server('http_server_1').hello_get }
end

When('I greet over gRPC') do
  capture_result { grpc_client_for_server('grpc_server_1').say_hello(greeter_request) }
end

When('I greet over gRPC with a short deadline') do
  capture_result { grpc_client_for_server('grpc_server_1', timeout: 1).say_hello(greeter_request) }
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
  expect(@error).to be_nil
  expect(@response.code).to eq(200)
end

Then('I should receive a http not found response') do
  expect(@error).to be_nil
  expect(@response.code).to eq(404)
end

Then('I should receive a connection error for metrics response with HTTP') do
  expect(@error).to be_a(StandardError)
end

Then('I should receive a delay error for hello response with HTTP') do
  expect(@error).to be_a(RestClient::Exceptions::ReadTimeout)
end

Then('I should receive a invalid data error for hello response with HTTP') do
  expect(@error).to be_a(Net::HTTPBadResponse)
end

Then('I should receive a connection error for being greeted with gRPC') do
  expect(@error).to be_a(GRPC::Unavailable)
end

Then('I should receive a delay error for being greeted with gRPC') do
  expect(@error).to be_a(GRPC::DeadlineExceeded)
end

Then('I should receive a invalid data error for being greeted with gRPC') do
  expect(@error).to be_a(StandardError)
end

Then('I should receive a successful response from the http proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(200)
end

Then('I should receive a not found response from the http proxy server') do
  expect(@error).to be_nil
  expect(@response.code).to eq(404)
end

Then('I should receive the {string} request details from the local http proxy server') do |verb|
  body = JSON.parse(@response.body)

  expect(@error).to be_nil
  expect(@response.code).to eq(200)
  expect(body).to include(
    'method' => verb,
    'body' => 'Hello World!',
    'content_type' => 'application/json',
    'content_length' => '12'
  )
end
