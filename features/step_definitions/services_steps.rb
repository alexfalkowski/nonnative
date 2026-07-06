# frozen_string_literal: true

require 'fileutils'

Given('I configure the system programmatically with services') do
  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_000, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
  end
end

Given('I configure the system programmatically with services without proxies') do
  configure_with_defaults do |config|
    add_service(config, name: 'service_1', host: '127.0.0.1', port: 30_000)
  end
end

Given('I configure the system programmatically with services and missing upstreams') do
  FileUtils.rm_f('test/reports/proxy_service_1.log')

  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_001, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
  end
end

Given('I configure the system programmatically with service TCP readiness') do
  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      readiness: [{ kind: 'tcp', host: '127.0.0.1', port: 30_000 }],
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_000, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
  end
end

Given('I configure the system programmatically with missing service TCP readiness') do
  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      timeout: 0.1,
      readiness: [{ kind: 'tcp', host: '127.0.0.1', port: 30_001 }],
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_000, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
  end
end

Given('I configure the system programmatically with a process and missing service TCP readiness') do
  @service_readiness_process_output = 'test/reports/service_readiness_process_output'
  FileUtils.rm_f(@service_readiness_process_output)

  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      timeout: 0.1,
      readiness: [{ kind: 'tcp', host: '127.0.0.1', port: 30_001 }],
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_000, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
    add_process(
      config,
      name: 'service_readiness_process',
      command: -> { [RbConfig.ruby, 'features/support/bin/start', '12418', @service_readiness_process_output] },
      timeout: 2,
      wait: 0.1,
      host: '127.0.0.1',
      ports: [12_418],
      log: 'test/reports/12_418.log',
      signal: 'INT'
    )
  end
end

Given('I configure the system programmatically with unresolvable service TCP readiness') do
  configure_with_defaults do |config|
    add_service(
      config,
      name: 'service_1',
      host: '127.0.0.1',
      port: 20_006,
      timeout: 0.1,
      readiness: [{ kind: 'tcp', host: 'nonnative.invalid', port: 30_001 }],
      proxy: { kind: 'fault_injection', host: '127.0.0.1', port: 30_000, log: 'test/reports/proxy_service_1.log', wait: 0.1, options: { delay: 0.1 } }
    )
  end
end

Given('I configure the system through configuration with services') do
  load_configuration('features/configs/services.yml')
end

When('I connect to the service') do
  @service = Nonnative::Features::TCPClient.new('localhost', configured_service('service_1').port).connect
end

When('I send {string} to the service') do |message|
  @service.write(message)
end

When('I stop the service runner {string}') do |name|
  Nonnative.pool.service_by_name(name).stop
end

When('I stop the service runner {string} while clients connect') do |name|
  service = configured_service(name)
  runner = Nonnative.pool.service_by_name(name)

  20.times do |iteration|
    runner.start if iteration.positive?
    stop_service_runner_while_clients_connect(runner, service)

    break if @stop_error
  end
end

When('I receive data from the service') do
  @service_response = @service.receive
end

When('I receive data from the service with a {float} second timeout') do |duration|
  @service_response = Timeout.timeout(duration) { @service.receive }
rescue Timeout::Error => e
  @service_response = e
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

Then('I should receive a timeout from the service') do
  expect(@service_response).to be_a(Timeout::Error)
end

Then('I should get a proxy not found error') do
  expect(@error).to be_a(Nonnative::NotFoundError)
end

Then('stopping the service runner should succeed') do
  expect(@stop_error).to be_nil
end

Then('the service readiness process side effect should not happen') do
  expect(File.exist?(@service_readiness_process_output)).to eq(false)
end

Then('the proxy for service {string} should use host {string} and port {int}') do |name, host, port|
  proxy = Nonnative.pool.service_by_name(name).proxy

  expect(proxy.host).to eq(host)
  expect(proxy.port).to eq(port)
end

Then('I should have a successful connection') do
  expect(@service).not_to be_closed
end
