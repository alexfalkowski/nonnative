# frozen_string_literal: true

When('I create the go command with output {string} and executable {string} and command {string} and parameters {string}') do |output, exec, cmd, params|
  @exec_path = Nonnative.go_executable(output, exec, cmd, params)
end

When('I load the go configuration') do
  Nonnative.configure do |config|
    config.load_file('features/configs/go.yml')
  end

  @exec_path = Nonnative.configuration.processes.first.command
end

Then('I should have a valid go command with output {string} and executable {string} and command {string} and parameters {string}') do |output, exec, cmd, params|
  parts = @exec_path.split

  expect(parts.first).to eq(exec)

  if params == ''
    expect(parts.last).to eq(cmd)

    parts = parts[1..parts.length - 2]
  else
    expect(parts[parts.length - 2]).to eq(cmd)
    expect(parts.last).to eq(params)

    parts = parts[1..parts.length - 3]
  end

  parts.each do |p|
    expect(p).to include("#{output}/#{exec}-#{cmd}")
  end
end
