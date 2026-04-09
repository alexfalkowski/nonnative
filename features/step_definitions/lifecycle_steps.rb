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

When('I check whether a reaped process still exists') do
  process = Nonnative::Process.new(Nonnative::ConfigurationProcess.new)
  pid = spawn(RbConfig.ruby, '-e', 'exit 0')
  Process.wait(pid)

  process.instance_variable_set(:@pid, pid)
  @process_exists = process.send(:process_exists?)
end

Then('starting the system should raise an error containing {string}') do |message|
  expect { Nonnative.start }.to raise_error(Nonnative::StartError, /#{Regexp.escape(message)}/)
end

Then('stopping the system should raise an error containing {string}') do |message|
  expect { Nonnative.stop }.to raise_error(Nonnative::StopError, /#{Regexp.escape(message)}/)
end

Then('the lifecycle errors should include {string}') do |message|
  expect(@lifecycle_errors).to include(message)
end

Then('the process should no longer exist') do
  expect(@process_exists).to eq(false)
end

def build_pool(services: [], servers: [], processes: [])
  Nonnative::Features::SeededPool.new(Nonnative::Configuration.new, services:, servers:, processes:)
end
