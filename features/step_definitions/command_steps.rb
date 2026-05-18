# frozen_string_literal: true

When('I create a go command with:') do |table|
  rows = table.rows_hash
  params = rows['parameters']
  params = nil if params == ''

  @exec_path = Nonnative.go_executable_args([], rows['output'], rows['executable'], rows['command'], params)
end

When('I load the go configuration') do
  Nonnative.configure do |config|
    config.load_file('features/configs/go.yml')
  end

  @exec_path = Nonnative.configuration.processes.first.command.call
end

Then('I should have a valid go command argv with:') do |table|
  expect(@exec_path).to be_an(Array)
  expect_valid_go_command(table, @exec_path)
end

def expect_valid_go_command(table, parts)
  rows = table.rows_hash
  params = rows['parameters']
  output = rows['output']
  exec = rows['executable']
  cmd = rows['command']

  expect(parts.first).to eq(exec)
  parts = expect_go_command_parts(parts, cmd, params)

  expect_go_command_flags(parts, output, exec, cmd)
end

def expect_go_command_parts(parts, cmd, params)
  return expect_go_command_without_params(parts, cmd) if params == ''

  expect(parts[-2]).to eq(cmd)
  expect(parts.last).to eq(params)

  parts[1..-3]
end

def expect_go_command_without_params(parts, cmd)
  expect(parts.last).to eq(cmd)

  parts[1..-2]
end

def expect_go_command_flags(parts, output, exec, cmd)
  parts.each { |p| expect(p).to include("#{output}/#{exec}-#{cmd}") }
end
