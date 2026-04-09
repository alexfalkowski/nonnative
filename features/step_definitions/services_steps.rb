# frozen_string_literal: true

Given('I configure the system programmatically with services') do
  configure_services_programmatically
end

Given('I configure the system through configuration with services') do
  load_configuration('features/configs/services.yml')
end

When('I connect to the service') do
  @service = Nonnative::Features::Service.new(configured_service('service_1').port)
end

When('I receive data from the service') do
  @service_response = @service.receive
end

When('I try to find the proxy for service {string}') do |name|
  capture_result(:@service_runner, :@error) { Nonnative.pool.service_by_name(name) }
end

Then('I should receive a connection error from the service') do
  expect(@service_response).to be_nil
end

Then('I should have a successful connection') do
  expect(@service).not_to be_closed
end
