# frozen_string_literal: true

When('I create the go command with output {string} and executable {string} and command {string} and parameters {string}') do |output, exec, cmd, params|
  @exec_path = Nonnative.go_executable(output, exec, cmd, params)
end

Then('the go command should be {string}') do |output|
  expect(@exec_path).to eq(output)
end