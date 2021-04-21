# frozen_string_literal: true

Given('I have an executable {string} with output {string}') do |exec, output|
  @command = Nonnative::GoCommand.new(exec, output)
end

When('I create the go command with command {string} and parameters {string}') do |cmd, params|
  @exec_path = @command.executable(cmd, params)
end

Then('the go command should be {string}') do |output|
  expect(@exec_path).to eq(output)
end
