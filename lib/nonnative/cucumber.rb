# frozen_string_literal: true

World(RSpec::Benchmark::Matchers)

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
