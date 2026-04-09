# frozen_string_literal: true

Given('I load a temporary configuration with a service entry') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    services:
      - name: service_1
        host: 127.0.0.1
        port: 20006
        proxy:
          kind: fault_injection
          host: 127.0.0.1
          port: 30000
          log: test/reports/proxy_service_1.log
  YAML
end

Given('I load a temporary configuration with split service and proxy endpoints') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    services:
      - name: service_1
        host: 127.0.0.1
        port: 20006
        proxy:
          kind: fault_injection
          host: 127.0.0.1
          port: 30000
          log: test/reports/proxy_service_1.log
  YAML
end

Given('I load a temporary configuration with a top-level wait and a process') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    wait: 10
    processes:
      - name: default_wait_process
        command: features/support/bin/start 12_399
        timeout: 1
        host: 127.0.0.1
        port: 12399
        log: test/reports/12_399.log
  YAML
end

Then('the configuration should contain {int} service entry and {int} process entries') do |services, processes|
  expect(Nonnative.configuration.services.size).to eq(services)
  expect(Nonnative.configuration.processes.size).to eq(processes)
end

Then('the configured service {string} should use host {string} and port {int}') do |name, host, port|
  service = configured_service(name)

  expect(service.host).to eq(host)
  expect(service.port).to eq(port)
end

Then('the configured service {string} proxy should use host {string} and port {int}') do |name, host, port|
  service = configured_service(name)

  expect(service.proxy.host).to eq(host)
  expect(service.proxy.port).to eq(port)
end

Then('the configured process {string} should have wait {float}') do |name, wait|
  process = configured_process(name)

  expect(process.wait).to eq(wait)
end

def load_temporary_configuration(contents)
  path = "test/reports/#{SecureRandom.hex(4)}.yml"
  File.write(path, contents)

  load_configuration(path)
end
