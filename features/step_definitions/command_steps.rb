# frozen_string_literal: true

When('I create a go argv with:') do |table|
  rows = table.rows_hash
  params = rows['parameters']
  params = nil if params == ''

  @exec_path = Nonnative.go_argv([], rows['output'], rows['executable'], rows['command'], params)
end

When('I create a go command string with:') do |table|
  rows = table.rows_hash
  params = rows['parameters']
  params = params.split(',') unless params == ''

  @exec_path = Nonnative.go_command([], rows['output'], rows['executable'], rows['command'], *params)
end

When('I load the go configuration') do
  Nonnative.configure do |config|
    config.load_file('features/configs/go.yml')
  end

  @exec_path = Nonnative.configuration.processes.first.command.call
end

Then('I should have a valid go command argv with:') do |table|
  expect(@exec_path).to be_an(Array)
  expect(@exec_path).to match_go_command(table)
end

Then('I should have a valid go command string with:') do |table|
  expect(@exec_path).to be_a(String)
  expect(Shellwords.split(@exec_path)).to match_go_command(table)
end
