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

Given('I load a temporary configuration with multiple runner ports') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    processes:
      - name: multi_port_process
        command: features/support/bin/start 12_420,12_421
        timeout: 1
        host: 127.0.0.1
        ports:
          - 12420
          - 12421
        log: test/reports/12_420.log
  YAML
end

Given('I load a temporary configuration with proxy options') do
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
          options:
            delay: 5
  YAML
end

Given('I load a temporary configuration with a server entry') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    servers:
      - name: server_1
        class: Nonnative::Features::TCPServer
        timeout: 1
        ports:
          - 12401
        log: test/reports/server_1.log
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
        ports:
          - 12399
        log: test/reports/12_399.log
  YAML
end

Given('I load a temporary configuration with omitted runner timeouts') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    processes:
      - name: default_timeout_process
        command: features/support/bin/start 12_398
        ports:
          - 12398
        log: test/reports/12_398.log
    servers:
      - name: default_timeout_server
        class: Nonnative::Features::TCPServer
        ports:
          - 12397
        log: test/reports/default_timeout_server.log
  YAML
end

Given('I load a temporary configuration with explicit runner timeouts') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    processes:
      - name: explicit_timeout_process
        command: features/support/bin/start 12_396
        timeout: 2.5
        ports:
          - 12396
        log: test/reports/12_396.log
    servers:
      - name: explicit_timeout_server
        class: Nonnative::Features::TCPServer
        timeout: 3.5
        ports:
          - 12395
        log: test/reports/explicit_timeout_server.log
  YAML
end

Given('I load a temporary configuration containing ERB') do
  @erb_side_effect_path = "test/reports/#{SecureRandom.hex(4)}"
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: <%= File.write(#{@erb_side_effect_path.inspect}, 'evaluated') %>
    url: http://localhost:4567
    log: test/reports/nonnative.log
  YAML
end

Given('I load a temporary configuration with omitted hosts') do
  load_temporary_configuration(<<~YAML)
    version: "1.0"
    name: test
    url: http://localhost:4567
    log: test/reports/nonnative.log
    processes:
      - name: default_host_process
        command: features/support/bin/start 12_400
        timeout: 1
        ports:
          - 12400
        log: test/reports/12_400.log
  YAML
end

When('I attempt to load a temporary configuration with a process proxy') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(<<~YAML)
      version: "1.0"
      name: test
      url: http://localhost:4567
      log: test/reports/nonnative.log
      processes:
        - name: process_proxy
          command: features/support/bin/start 12_400
          timeout: 1
          ports:
            - 12400
          log: test/reports/12_400.log
          proxy:
            kind: fault_injection
            port: 30000
            log: test/reports/proxy_process.log
    YAML
  end
end

When('I attempt to load a temporary configuration with a server proxy') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(<<~YAML)
      version: "1.0"
      name: test
      url: http://localhost:4567
      log: test/reports/nonnative.log
      servers:
        - name: server_proxy
          class: Nonnative::Features::TCPServer
          timeout: 1
          ports:
            - 12400
          log: test/reports/server_proxy.log
          proxy:
            kind: fault_injection
            port: 30000
            log: test/reports/proxy_server.log
    YAML
  end
end

When('I attempt to load a temporary configuration with a Ruby object tag') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(<<~YAML)
      --- !ruby/object:Object
      version: "1.0"
      name: test
    YAML
  end
end

When('I attempt to load a temporary configuration with a singular runner port') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(<<~YAML)
      version: "1.0"
      name: test
      url: http://localhost:4567
      log: test/reports/nonnative.log
      processes:
        - name: legacy_port_process
          command: features/support/bin/start 12_400
          timeout: 1
          port: 12400
          log: test/reports/12_400.log
    YAML
  end
end

When('I attempt to load a temporary configuration with plural service ports') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(<<~YAML)
      version: "1.0"
      name: test
      url: http://localhost:4567
      log: test/reports/nonnative.log
      services:
        - name: legacy_ports_service
          host: 127.0.0.1
          ports:
            - 12400
          proxy:
            kind: fault_injection
            host: 127.0.0.1
            port: 30000
            log: test/reports/proxy_legacy_ports_service.log
    YAML
  end
end

When('I attempt to configure a service with plural ports') do
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    Nonnative.configure do |config|
      config.service do |service|
        service.name = 'legacy_ports_service'
        service.ports = [12_400]
      end
    end
  end
end

When('I attempt to read plural ports from a configured service') do
  @configuration_error = nil
  Nonnative.configure do |config|
    config.service do |service|
      service.name = 'legacy_ports_service'
      service.port = 12_400
    end
  end

  capture_result(:@configuration_result, :@configuration_error) do
    configured_service('legacy_ports_service').ports
  end
end

When('I attempt to load a temporary configuration with {string} YAML') do |kind|
  @configuration_error = nil
  capture_result(:@configuration_result, :@configuration_error) do
    load_temporary_configuration(malformed_yaml(kind))
  end
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

Then('the configured process {string} should use ports:') do |name, table|
  process = configured_process(name)

  expect(process.ports).to eq(table.raw.flatten.map(&:to_i))
end

Then('the configured service {string} proxy should use host {string} and port {int}') do |name, host, port|
  service = configured_service(name)

  expect(service.proxy.host).to eq(host)
  expect(service.proxy.port).to eq(port)
end

Then('the configured service {string} proxy option {string} should be {int}') do |name, option, value|
  service = configured_service(name)

  expect(service.proxy.options[option.to_sym]).to eq(value)
end

Then('the configured server {string} should use class {string}') do |name, klass|
  server = configured_server(name)

  expect(server.klass).to eq(Object.const_get(klass))
end

Then('the configured process {string} should have wait {float}') do |name, wait|
  process = configured_process(name)

  expect(process.wait).to eq(wait)
end

Then('the configured process {string} should have timeout {float}') do |name, timeout|
  process = configured_process(name)

  expect(process.timeout).to eq(timeout)
end

Then('the configured server {string} should have timeout {float}') do |name, timeout|
  server = configured_server(name)

  expect(server.timeout).to eq(timeout)
end

Then('the configured process {string} should use host {string}') do |name, host|
  process = configured_process(name)

  expect(process.host).to eq(host)
end

Then('the ERB side effect should not happen') do
  expect(File.exist?(@erb_side_effect_path)).to be(false)
end

Then('the configuration name should be the ERB source') do
  expect(Nonnative.configuration.name).to eq("<%= File.write(#{@erb_side_effect_path.inspect}, 'evaluated') %>")
end

Then('loading the configuration should fail with a YAML safety error') do
  expect(@configuration_error).to be_a(Psych::DisallowedClass)
end

Then('loading the configuration should fail with an argument error containing {string}') do |message|
  expect(@configuration_error).to be_a(ArgumentError)
  expect(@configuration_error.message).to include(message)
end
