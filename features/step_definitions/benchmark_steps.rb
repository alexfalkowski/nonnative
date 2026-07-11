# frozen_string_literal: true

Given('I configure the system programmatically with a no op server') do
  configure_with_defaults do |config|
    add_server(config, klass: Nonnative::Features::NoOpServer, timeout: 1, ports: [14_000])
  end
end

Given('I configure the system programmatically with a server that raises before readiness') do
  configure_with_defaults do |config|
    add_server(config, klass: Nonnative::Features::RaiseStartServer, timeout: 1, ports: [14_008])
  end
end

Given('I configure the system programmatically with a no stop server') do
  configure_with_defaults do |config|
    add_server(config, klass: Nonnative::Features::NoStopServer, timeout: 1, ports: [14_001])
  end
end

Given('I configure the system programmatically with a start error server') do
  configure_with_defaults do |config|
    add_server(
      config,
      name: 'rollback_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::TCPServer,
      timeout: 1,
      ports: [14_002],
      log: 'test/reports/14_002.log'
    )
    add_server(
      config,
      name: 'fail_start_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::FailStartServer,
      timeout: 1,
      ports: [14_003],
      log: 'test/reports/14_003.log'
    )
  end
end

Given('I configure the system programmatically with a fast exiting process') do
  configure_with_defaults do |config|
    add_process(
      config,
      name: 'fast_exit_process',
      command: -> { "#{RbConfig.ruby} -e \"exit 23\"" },
      timeout: 1,
      wait: 1,
      host: '127.0.0.1',
      ports: [14_006],
      log: 'test/reports/14_006.log',
      signal: 'INT'
    )
  end
end

Given('I configure the system programmatically with a signal terminated process') do
  configure_with_defaults do |config|
    add_process(
      config,
      name: 'signal_exit_process',
      command: -> { [RbConfig.ruby, '-e', 'Process.kill("KILL", Process.pid)'] },
      timeout: 1,
      wait: 1,
      host: '127.0.0.1',
      ports: [14_007],
      log: 'test/reports/14_007.log',
      signal: 'INT'
    )
  end
end

Given('I configure the system programmatically with a stop error server') do
  configure_with_defaults do |config|
    add_server(
      config,
      name: 'fail_stop_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::FailStopServer,
      timeout: 1,
      ports: [14_004],
      log: 'test/reports/14_004.log'
    )
    add_server(
      config,
      name: 'cleanup_server',
      host: '127.0.0.1',
      klass: Nonnative::Features::TCPServer,
      timeout: 1,
      ports: [14_005],
      log: 'test/reports/14_005.log'
    )
  end
end

Then('starting the system should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stopping the system should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end

Then('the port {string} should be closed') do |port|
  wait_for { port_closed?(port.to_i) }.to eq(true)
end
