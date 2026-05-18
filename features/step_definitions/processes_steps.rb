# frozen_string_literal: true

Given('I configure the system programmatically with processes') do
  configure_processes_programmatically
end

Given('I configure the system through configuration with processes') do
  load_configuration('features/configs/processes.yml')
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
      process.port = 12_401
      process.log = 'test/reports/12_401.log'
      process.signal = 'INT'
    end
  end
end

When('I send {string} with the TCP client to the processes') do |message|
  @responses = %w[start_1 start_2].map { |name| tcp_client_for_process(name).request(message) }
end

When('I send {string} with the TCP client {string} to the process') do |message, name|
  @response = tcp_client_for_process(name).request(message)
end

When('I try to find the proxy for process {string}') do |name|
  capture_result(:@process, :@error) { Nonnative.pool.process_by_name(name) }
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

Then('I should receive a connection error for client response with TCP') do
  expect(@response).to be_a Errno::ECONNRESET
end

Then('I should receive a invalid data that is not {string} for client response with TCP') do |message|
  expect(@response).not_to eq(message)
end
