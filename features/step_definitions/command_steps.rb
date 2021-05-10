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

Then('the go command should be {string}') do |output|
  expect(@exec_path).to eq(output)
end
