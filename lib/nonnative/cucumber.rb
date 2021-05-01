# frozen_string_literal: true

Given('I set the proxy for process {string} to {string}') do |name, operation|
  server = Nonnative.pool.process_by_name(name)
  server.proxy.send(operation)
end

Given('I set the proxy for server {string} to {string}') do |name, operation|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.send(operation)
end

Given('I set the proxy for service {string} to {string}') do |name, operation|
  service = Nonnative.pool.service_by_name(name)
  service.proxy.send(operation)
end

Then('I should reset the proxy for process {string}') do |name|
  server = Nonnative.pool.process_by_name(name)
  server.proxy.reset
end

Then('I should reset the proxy for server {string}') do |name|
  server = Nonnative.pool.server_by_name(name)
  server.proxy.reset
end

Then('I should reset the proxy for service {string}') do |name|
  service = Nonnative.pool.service_by_name(name)
  service.proxy.reset
end
