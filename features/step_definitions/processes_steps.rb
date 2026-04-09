# frozen_string_literal: true

Given('I configure the system programmatically with processes') do
  configure_processes_programmatically
end

Given('I configure the system through configuration with processes') do
  load_configuration('features/configs/processes.yml')
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

Then('I should receive a connection error for client response with TCP') do
  expect(@response).to be_a Errno::ECONNRESET
end

Then('I should receive a invalid data that is not {string} for client response with TCP') do |message|
  expect(@response).not_to eq(message)
end
