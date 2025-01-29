# frozen_string_literal: true

World(RSpec::Benchmark::Matchers)
World(RSpec::Matchers)
World(RSpec::Wait)

Before('@startup') do
  Nonnative.start
end

After('@startup') do
  Nonnative.stop
end

After('@manual') do
  Nonnative.stop
end

Before('@clear') do
  Nonnative.clear
end

After('@reset') do
  Nonnative.reset
end

Given('I set the proxy for process {string} to {string}') do |name, operation|
  process = Nonnative.pool.process_by_name(name)
  process.proxy.send(operation)
end

Given('I set the proxy for server {string} to {string}') do |name, operation|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.send(operation)
end

Given('I set the proxy for service {string} to {string}') do |name, operation|
  service = Nonnative.pool.service_by_name(name)
  service.proxy.send(operation)
end

Given('I start the system') do
  Nonnative.start
end

Given('I should see {string} as unhealthy') do |service|
  opts = {
    headers: { content_type: :json, accept: :json },
    read_timeout: 10, open_timeout: 10
  }

  wait_for do
    @response = Nonnative.observability.health(opts)
    @response.code
  end.to eq(503)

  expect(@response.body).to include(service)
end

Then('I should reset the proxy for process {string}') do |name|
  process = Nonnative.pool.process_by_name(name)
  process.proxy.reset
end

Then('I should reset the proxy for server {string}') do |name|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.reset
end

Then('I should reset the proxy for service {string}') do |name|
  service = Nonnative.pool.service_by_name(name)
  service.proxy.reset
end

Then('the process {string} should consume less than {string} of memory') do |name, mem|
  process = Nonnative.pool.process_by_name(name)
  _, size, type = mem.split(/(\d+)/)
  actual = process.memory.send(type)
  size = size.to_i

  expect(actual).to be < size
end

Then('starting the system should raise an error') do
  expect { Nonnative.start }.to raise_error(Nonnative::StartError)
end

Then('stopping the system should raise an error') do
  expect { Nonnative.stop }.to raise_error(Nonnative::StopError)
end

Then('I should see a log entry of {string} for process {string}') do |message, process|
  process = Nonnative.configuration.process_by_name(process)
  expect(Nonnative.log_lines(process.log, ->(l) { l.include?(message) }).first).to include(message)
end

Then('I should see a log entry of {string} in the file {string}') do |message, path|
  expect(Nonnative.log_lines(path, ->(l) { l.include?(message) }).first).to include(message)
end

Then('I should see {string} as healthy') do |service|
  opts = {
    headers: { content_type: :json, accept: :json },
    read_timeout: 10, open_timeout: 10
  }

  wait_for do
    @response = Nonnative.observability.health(opts)
    @response.code
  end.to eq(200)

  expect(@response.body).to_not include(service)
end
