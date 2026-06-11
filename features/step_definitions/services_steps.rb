# frozen_string_literal: true

Given('I configure the system programmatically with services') do
  configure_services_programmatically
end

Given('I configure the system programmatically with services without proxies') do
  configure_services_without_proxies_programmatically
end

Given('I configure the system programmatically with services and missing upstreams') do
  configure_services_with_missing_upstreams_programmatically
end

Given('I configure the system through configuration with services') do
  load_configuration('features/configs/services.yml')
end

When('I connect to the service') do
  @service = Nonnative::Features::Service.new(configured_service('service_1').port)
end

When('I send {string} to the service') do |message|
  @service.write(message)
end

When('I stop the service runner {string}') do |name|
  Nonnative.pool.service_by_name(name).stop
end

When('I receive data from the service') do
  @service_response = @service.receive
end

When('I try to find the proxy for service {string}') do |name|
  capture_result(:@service_runner, :@error) { Nonnative.pool.service_by_name(name) }
end

Then('I should receive a connection error from the service') do
  expect(@service_response).not_to be_a(String)
  expect(connection_error?(@service_response)).to be(true)
end

Then('I should receive {string} from the service') do |response|
  expect(@service_response).to eq(response)
end

Then('I should receive an invalid service response that is not {string}') do |message|
  expect(@service_response).to be_a(String)
  expect(@service_response).not_to be_empty
  expect(@service_response).not_to eq(message)
end

Then('I should get a proxy not found error') do
  expect(@error).to be_a(Nonnative::NotFoundError)
end

Then('the proxy for service {string} should use host {string} and port {int}') do |name, host, port|
  proxy = Nonnative.pool.service_by_name(name).proxy

  expect(proxy.host).to eq(host)
  expect(proxy.port).to eq(port)
end

Then('I should have a successful connection') do
  expect(@service).not_to be_closed
end
