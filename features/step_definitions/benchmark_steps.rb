# frozen_string_literal: true

When('I configure the system programmatically with a no op server') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.name = 'test'
    config.url = 'http://localhost:4567'
    config.log = 'test/reports/nonnative.log'

    config.server do |d|
      d.klass = Nonnative::Features::NoOpServer
      d.timeout = 1
      d.port = 14_000
    end
  end
end

When('I configure the system programmatically with a no stop server') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.name = 'test'
    config.url = 'http://localhost:4567'
    config.log = 'test/reports/nonnative.log'

    config.server do |d|
      d.klass = Nonnative::Features::NoStopServer
      d.timeout = 1
      d.port = 14_001
    end
  end
end

When('I configure the system programmatically with a start error server') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.name = 'test'
    config.url = 'http://localhost:4567'
    config.log = 'test/reports/nonnative.log'

    config.server do |d|
      d.name = 'rollback_server'
      d.host = '127.0.0.1'
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 14_002
      d.log = 'test/reports/14_002.log'
    end

    config.server do |d|
      d.name = 'fail_start_server'
      d.host = '127.0.0.1'
      d.klass = Nonnative::Features::FailStartServer
      d.timeout = 1
      d.port = 14_003
      d.log = 'test/reports/14_003.log'
    end
  end
end

When('I configure the system programmatically with a fast exiting process') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.name = 'test'
    config.url = 'http://localhost:4567'
    config.log = 'test/reports/nonnative.log'

    config.process do |d|
      d.name = 'fast_exit_process'
      d.command = -> { "#{RbConfig.ruby} -e \"exit 0\"" }
      d.timeout = 1
      d.wait = 1
      d.host = '127.0.0.1'
      d.port = 14_006
      d.log = 'test/reports/14_006.log'
      d.signal = 'INT'
      d.proxy = {
        kind: 'fault_injection',
        host: '127.0.0.1',
        port: 24_006,
        log: 'test/reports/proxy_14_006.log',
        wait: 0.1
      }
    end
  end
end

Given('I configure the system programmatically with a stop error server') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.name = 'test'
    config.url = 'http://localhost:4567'
    config.log = 'test/reports/nonnative.log'

    config.server do |d|
      d.name = 'fail_stop_server'
      d.host = '127.0.0.1'
      d.klass = Nonnative::Features::FailStopServer
      d.timeout = 1
      d.port = 14_004
      d.log = 'test/reports/14_004.log'
    end

    config.server do |d|
      d.name = 'cleanup_server'
      d.host = '127.0.0.1'
      d.klass = Nonnative::Features::TCPServer
      d.timeout = 1
      d.port = 14_005
      d.log = 'test/reports/14_005.log'
    end
  end
end

Then('starting the system should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stopping the system should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end

Then('the port {string} should be closed') do |port|
  wait_for do
    socket = TCPSocket.new('127.0.0.1', port.to_i)
    socket.close

    false
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    true
  end.to eq(true)
end
