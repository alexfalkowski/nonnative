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

Given('I start the system') do
  Nonnative.start
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

Then('I should see a log entry of {string} in the file {string}') do |message, path|
  expect(Nonnative.log_lines(path, ->(l) { l.include?(message) }).first).to include(message)
end
