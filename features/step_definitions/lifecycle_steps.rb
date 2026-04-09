# frozen_string_literal: true

Given('I configure a pool that raises on start') do
  Nonnative.pool = Nonnative::Features::StubPool.new(start_error: StandardError.new('boom on start'))
end

Given('I configure a pool that raises on stop') do
  Nonnative.pool = Nonnative::Features::StubPool.new(stop_error: StandardError.new('boom on stop'))
end

Given('I configure a pool that fails to start and raises on rollback') do
  Nonnative.pool = (
    Nonnative::Features::StubPool.new(
      start_errors: ['boom on startup'],
      rollback_error: StandardError.new('boom on rollback')
    )
  )
end

When('I start a pool with a failing unnamed service') do
  @lifecycle_errors = build_pool(
    services: [Nonnative::Features::FailingService.new(start_error: 'boom on service start')]
  ).start
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
  run_subprocess(<<~RUBY)
    require 'nonnative'

    module Nonnative
      class << self
        def start
          puts 'started'
        end

        def stop
          puts 'stopped'
        end
      end
    end

    require #{path.inspect}
  RUBY
end

Then('starting the system should raise an error containing {string}') do |message|
  expect(@start_error).to be_a(Nonnative::StartError)
  expect(@start_error.message).to include(message)
end

Then('stopping the system should raise an error containing {string}') do |message|
  expect(@stop_error).to be_a(Nonnative::StopError)
  expect(@stop_error.message).to include(message)
end

Then('the lifecycle errors should include {string}') do |message|
  expect(@lifecycle_errors).to include(message)
end

Then('the lifecycle errors should be empty') do
  expect(@lifecycle_errors).to eq([])
end

Then('the lifecycle order should be:') do |table|
  expect(@lifecycle_events).to eq(table.raw.flatten)
end

Then('the process should no longer exist') do
  expect(@process_exists).to eq(false)
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

def build_pool(services: [], servers: [], processes: [])
  Nonnative::Features::SeededPool.new(Nonnative::Configuration.new, services:, servers:, processes:)
end

def build_ordered_pool(events)
  build_pool(
    services: [Nonnative::Features::RecordingService.new(name: 'service_1', events:)],
    servers: [[
      Nonnative::Features::RecordingRunner.new(name: 'server_1', events:),
      Nonnative::Features::PassingPort.new
    ]],
    processes: [[
      Nonnative::Features::RecordingRunner.new(name: 'process_1', events:),
      Nonnative::Features::PassingPort.new
    ]]
  )
end

def configure_for_clear(log:, url:)
  Nonnative.configure do |config|
    config.name = 'test'
    config.url = url
    config.log = log
  end
end

def observability_host(client)
  client.send(:host)
end

def run_subprocess(script)
  @subprocess_stdout, @subprocess_stderr, @subprocess_status = Open3.capture3(
    RbConfig.ruby,
    '-Ilib',
    '-e',
    script,
    chdir: Dir.pwd
  )
end
