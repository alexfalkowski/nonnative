# frozen_string_literal: true

Given('I configure a pool that raises on start') do
  Nonnative.pool = Nonnative::Features::FailingPool.new(start_error: StandardError.new('boom on start'))
end

Given('I configure a pool that raises on stop') do
  Nonnative.pool = Nonnative::Features::FailingPool.new(stop_error: StandardError.new('boom on stop'))
end

Given('I configure the system with a process that does not exit during stop') do
  @lingering_processes = ['no_exit_process']

  configure_with_defaults do |config|
    add_lingering_process(config, 'no_exit_process', 12_410)
  end
end

Given('I configure a pool that fails to start and raises on rollback') do
  Nonnative.pool = (
    Nonnative::Features::FailingPool.new(
      start_errors: ['boom on startup'],
      rollback_error: StandardError.new('boom on rollback')
    )
  )
end

Given('I configure the system with a constructed server before a failing server') do
  configure_with_defaults do |config|
    add_server(
      config,
      name: 'constructed_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::TCPServer,
      timeout: 1,
      ports: [12_430],
      log: 'test/reports/12_430.log'
    )
    add_server(
      config,
      name: 'constructed_grpc_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::GRPCServer,
      timeout: 1,
      ports: [12_431],
      log: 'test/reports/12_431.log'
    )
    add_server(
      config,
      name: 'failing_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::EmptyHTTPServer,
      timeout: 1,
      ports: [12_432],
      log: 'test/reports/12_432.log'
    )
  end
end

Given('I configure the system with server cleanup and a timeout of {float} seconds') do |timeout|
  configure_with_defaults do |config|
    add_server(
      config,
      name: 'cleanup_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::CleanupServer,
      timeout:,
      wait: 0,
      ports: [12_434],
      log: 'test/reports/12_434.log'
    )
  end
end

Given('I configure the system with a restartable server and a timeout of {float} seconds') do |timeout|
  configure_with_defaults do |config|
    add_server(
      config,
      name: 'restartable_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::RestartableServer,
      timeout:,
      wait: 0,
      ports: [12_435],
      log: 'test/reports/12_435.log'
    )
  end
end

Given('I configure the system with a process that does not exit during rollback') do
  @lingering_processes = ['rollback_process']

  configure_with_defaults do |config|
    add_lingering_process(config, 'rollback_process', 12_411)
    add_fast_exit_process(config, 'rollback_failure_process', 12_412)
  end
end

Given('I configure the system with a process that opens only one configured port') do
  configure_with_defaults do |config|
    config.process do |process|
      process.name = 'partial_ports_process'
      process.command = -> { ['features/support/bin/start', '12415'] }
      process.timeout = 1
      process.wait = 0.1
      process.host = '127.0.0.1'
      process.ports = [12_415, 12_416]
      process.log = 'test/reports/12_415.log'
      process.signal = 'INT'
    end
  end
end

When('I start a pool with a failing unnamed service') do
  @lifecycle_errors = build_pool(
    services: [Nonnative::Features::FailingService.new(start_error: 'boom on service start')]
  ).start
end

When('I start a pool with a failing service and recording runners') do
  @lifecycle_events = []
  @lifecycle_errors = build_pool(
    services: [Nonnative::Features::FailingService.new(name: 'service_1', start_error: 'boom on service start')],
    servers: [[Nonnative::Features::RecordingRunner.new(name: 'server_1', events: @lifecycle_events), Nonnative::Features::PassingPort.new]],
    processes: [[Nonnative::Features::RecordingRunner.new(name: 'process_1', events: @lifecycle_events), Nonnative::Features::PassingPort.new]]
  ).start
end

When('I stop a pool with a failing unnamed service') do
  @lifecycle_errors = build_pool(
    services: [Nonnative::Features::FailingService.new(stop_error: 'boom on service stop')]
  ).stop
end

When('I start a pool with ordered services, servers, and processes') do
  @lifecycle_events = []
  @lifecycle_errors = build_ordered_pool(@lifecycle_events).start
end

When('I start a pool with a failing unnamed port check') do
  @lifecycle_errors = build_pool(
    servers: [[Nonnative::Features::FailingRunner.new, Nonnative::Features::FailingPort.new(open_error: 'boom on readiness')]]
  ).start
end

When('I stop a pool with a failing unnamed port check') do
  @lifecycle_errors = build_pool(
    servers: [[Nonnative::Features::FailingRunner.new, Nonnative::Features::FailingPort.new(closed_error: 'boom on shutdown')]]
  ).stop
end

When('I stop a pool with ordered services, servers, and processes') do
  @lifecycle_events = []
  @lifecycle_errors = build_ordered_pool(@lifecycle_events).stop
end

When('I check whether a reaped process still exists') do
  process = Nonnative::Process.new(Nonnative::ConfigurationProcess.new)
  pid = spawn(RbConfig.ruby, '-e', 'exit 0')
  Process.wait(pid)

  process.instance_variable_set(:@pid, pid)
  @process_exists = process.send(:process_exists?)
end

When('I perform a nonnative timeout with {word}') do |duration|
  time = { 'nil' => nil, 'zero' => 0, 'negative' => -1 }.fetch(duration)
  @timeout_result = Nonnative::Timeout.new(time).perform { :performed }
rescue StandardError => e
  @timeout_error = e
end

When('I clear after memoizing logger and observability') do
  @first_log_path = "test/reports/#{SecureRandom.hex(4)}-first.log"
  @second_log_path = "test/reports/#{SecureRandom.hex(4)}-second.log"
  @first_url = 'http://127.0.0.1:41001'
  @second_url = 'http://127.0.0.1:41002'

  configure_for_clear(log: @first_log_path, url: @first_url)
  @first_logger = Nonnative.logger
  @first_logger.info('before clear')
  @first_observability = Nonnative.observability

  Nonnative.clear

  configure_for_clear(log: @second_log_path, url: @second_url)
  @second_logger = Nonnative.logger
  @second_logger.info('after clear')
  @second_observability = Nonnative.observability
end

When('I require {string} in a subprocess') do |path|
  run_subprocess(<<~RUBY)
    require #{path.inspect}
    puts 'ok'
  RUBY
end

When('I require {string} in an instrumented subprocess') do |path|
  run_subprocess(startup_hook_recording_script(path))
end

Then('starting the system should raise an error containing {string}') do |message|
  expect(@start_error).to be_a(Nonnative::StartError)
  expect(@start_error.message).to include(message)
end

Then('starting the system should raise an error containing:') do |table|
  expect(@start_error).to be_a(Nonnative::StartError)
  table.raw.flatten.each { |message| expect(@start_error.message).to include(message) }
end

Then('starting the system should not raise an error containing {string}') do |message|
  expect(@start_error).to be_a(Nonnative::StartError)
  expect(@start_error.message).not_to include(message)
end

Then('stopping the system should raise an error containing {string}') do |message|
  expect(@stop_error).to be_a(Nonnative::StopError)
  expect(@stop_error.message).to include(message)
end

Then('stopping the system should raise an error containing:') do |table|
  expect(@stop_error).to be_a(Nonnative::StopError)
  table.raw.flatten.each { |message| expect(@stop_error.message).to include(message) }
end

Then('stopping the system should not raise an error') do
  expect(@stop_error).to be_nil
end

Then('the lifecycle errors should include {string}') do |message|
  expect(@lifecycle_errors).to include(message)
end

Then('the lifecycle errors should be empty') do
  expect(@lifecycle_errors).to be_empty
end

Then('the lifecycle order should be empty') do
  expect(@lifecycle_events).to be_empty
end

Then('the nonnative timeout should return false') do
  expect(@timeout_result).to eq(false)
end

Then('the nonnative timeout should raise an argument error') do
  expect(@timeout_error).to be_a(ArgumentError)
end

Then('the lifecycle order should be:') do |table|
  expect(@lifecycle_events).to eq(table.raw.flatten)
end

Then('the process should no longer exist') do
  expect(@process_exists).to eq(false)
end

Then('the process {string} should no longer exist') do |name|
  process = Nonnative.pool.process_by_name(name)
  pid = process.instance_variable_get(:@pid)

  wait_for { process_alive?(pid) }.to eq(false)
end

Then('the port {string} should be reusable') do |port|
  server = TCPServer.new('127.0.0.1', port.to_i)
  server.close
end

Then('the port {string} should be open') do |port|
  wait_for { port_closed?(port.to_i) }.to eq(false)
end

Then('the server cleanup should be complete') do
  expect(Nonnative.pool.server_by_name('cleanup_server').cleanup_complete?).to eq(true)
end

Then('the logger should be recreated for the new configuration') do
  expect(@second_logger).not_to equal(@first_logger)
  expect(File.read(@first_log_path)).to include('before clear')
  expect(File.read(@first_log_path)).not_to include('after clear')
  expect(File.read(@second_log_path)).to include('after clear')
end

Then('the observability client should be recreated for the new configuration') do
  expect(@second_observability).not_to equal(@first_observability)
  expect(observability_host(@first_observability)).to eq(@first_url)
  expect(observability_host(@second_observability)).to eq(@second_url)
end

Then('the subprocess should exit successfully') do
  expect(@subprocess_status.success?).to eq(true), @subprocess_stderr
end

Then('the subprocess output should contain {string}') do |message|
  expect(@subprocess_stdout).to include(message)
end

Then('the subprocess output should be:') do |table|
  expect(@subprocess_stdout.lines.map(&:chomp).reject(&:empty?)).to eq(table.raw.flatten)
end

After do
  cleanup_lingering_processes
end
