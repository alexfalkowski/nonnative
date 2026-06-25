# frozen_string_literal: true

require 'fileutils'

Given('I configure the system programmatically with processes') do
  configure_processes_programmatically
end

Given('I configure the system through configuration with processes') do
  load_configuration('features/configs/processes.yml')
end

Given('I configure the system through configuration with a YAML argv process') do
  @yaml_argv_side_effect_path = 'test/reports/yaml_argv_side_effect'
  @yaml_environment_output_path = 'test/reports/yaml_environment.txt'

  FileUtils.rm_f(@yaml_argv_side_effect_path)
  FileUtils.rm_f(@yaml_environment_output_path)

  load_configuration('features/configs/process_argv.yml')
end

Given('I configure the system programmatically with an argv process') do
  @argv_side_effect_path = "test/reports/#{SecureRandom.hex(4)}"
  configure_with_defaults do |config|
    config.process do |process|
      process.name = 'argv_process'
      process.command = -> { ['features/support/bin/start', "12401; touch #{@argv_side_effect_path}"] }
      process.timeout = 5
      process.wait = 0.1
      process.host = '127.0.0.1'
      process.ports = [12_401]
      process.log = 'test/reports/12_401.log'
      process.signal = 'INT'
    end
  end
end

Given('I configure the system programmatically with a shell string process') do
  @shell_string_side_effect_path = "test/reports/#{SecureRandom.hex(4)}-shell-string"
  configure_with_defaults do |config|
    config.process do |process|
      process.name = 'shell_string_process'
      process.command = lambda {
        "printf configured > #{@shell_string_side_effect_path}; exec features/support/bin/start 12413"
      }
      process.timeout = 5
      process.wait = 0.1
      process.host = '127.0.0.1'
      process.ports = [12_413]
      process.log = 'test/reports/12_413.log'
      process.signal = 'INT'
    end
  end
end

Given('I configure the system programmatically with a process that has no stop signal') do
  configure_with_defaults do |config|
    config.process do |process|
      process.name = 'default_signal_process'
      process.command = -> { ['features/support/bin/start', '12414'] }
      process.timeout = 5
      process.wait = 0.1
      process.host = '127.0.0.1'
      process.ports = [12_414]
      process.log = 'test/reports/12_414.log'
    end
  end
end

Given('I configure the system programmatically with a process HTTP readiness check') do
  configure_http_readiness_process(status: 200)
end

Given('I configure the system programmatically with a failing process HTTP readiness check') do
  configure_http_readiness_process(status: 503)
end

Given('the parent environment variable {string} is {string}') do |name, value|
  @previous_environment ||= {}
  @previous_environment[name] = ENV.fetch(name, nil)
  ENV[name] = value
end

When('I send {string} with the TCP client to the processes') do |message|
  @responses = %w[start_1 start_2].map { |name| tcp_client_for_process(name).request(message) }
end

When('I start a process runner with environment {string} set to {string}') do |name, value|
  @environment_output_path = "test/reports/#{SecureRandom.hex(4)}-environment.txt"

  Nonnative.configure { |config| config.log = 'test/reports/nonnative.log' }

  process_config = Nonnative::ConfigurationProcess.new
  process_config.name = 'environment_process'
  process_config.command = lambda {
    [
      RbConfig.ruby,
      '-e',
      "File.write(ARGV.fetch(0), ENV.fetch(#{name.inspect}, '')); sleep",
      @environment_output_path
    ]
  }
  process_config.timeout = 1
  process_config.wait = 0.1
  process_config.log = "test/reports/#{SecureRandom.hex(4)}-environment.log"
  process_config.signal = 'INT'
  process_config.environment = { name => value, 'RUBYOPT' => '' }

  @environment_process = Nonnative::Process.new(process_config)
  @environment_process.start
end

When('I send {string} with the TCP client {string} to the process') do |message, name|
  @response = tcp_client_for_process(name).request(message)
end

Then('I should receive a TCP {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
end

Then('I should receive a TCP {string} response from the process') do |response|
  expect(@response).to eq(response)
end

Then('the argv process shell side effect should not happen') do
  expect(File.exist?(@argv_side_effect_path)).to be(false)
end

Then('the shell string process side effect should happen') do
  expect(File.read(@shell_string_side_effect_path)).to eq('configured')
end

Then('the YAML argv process shell side effect should not happen') do
  expect(File.exist?(@yaml_argv_side_effect_path)).to be(false)
end

Then('the process environment output should be {string}') do |value|
  wait_for { File.exist?(@environment_output_path) }.to eq(true)
  expect(File.read(@environment_output_path)).to eq(value)
end

Then('the YAML process environment output should be {string}') do |value|
  wait_for { File.exist?(@yaml_environment_output_path) }.to eq(true)
  expect(File.read(@yaml_environment_output_path)).to eq(value)
end

After do
  @environment_process&.stop

  next unless @previous_environment

  @previous_environment.each do |name, value|
    value.nil? ? ENV.delete(name) : ENV[name] = value
  end
end
