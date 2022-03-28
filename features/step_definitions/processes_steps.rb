# frozen_string_literal: true

Given('I configure nonnative programatically with processes') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.process do |d|
      d.name = 'start_1'
      d.command = -> { 'features/support/bin/start 20_005' }
      d.timeout = config.strategy.timeout
      d.port = 12_321
      d.log = 'features/logs/12_321.log'
      d.signal = 'INT'
      d.environment = {
        'STRING' => 'true'
      }
      d.proxy = {
        type: 'fault_injection',
        port: 20_005,
        log: 'features/logs/proxy_start_1.log',
        options: {
          delay: 10
        }
      }
    end

    config.process do |d|
      d.name = 'start_2'
      d.command = -> { 'features/support/bin/start 12_322' }
      d.timeout = config.strategy.timeout
      d.port = 12_322
      d.log = 'features/logs/12_322.log'
      d.signal = 'TERM'
    end
  end
end

Given('I configure nonnative through configuration with processes') do
  Nonnative.configure do |config|
    config.load_file('features/configs/processes.yml')
  end
end

Given('I start nonnative') do
  Nonnative.start
end

When('I send {string} with the TCP client to the processes') do |message|
  @responses = [
    Nonnative::Features::TCPClient.new(12_321).request(message),
    Nonnative::Features::TCPClient.new(12_322).request(message)
  ]
end

When('I send {string} with the TCP client {string} to the processe') do |message, name|
  client = case name
           when 'start_1'
             Nonnative::Features::TCPClient.new(12_321)
           when 'start_2'
             Nonnative::Features::TCPClient.new(12_322)
           end

  @response = client.request(message)
end

When('I try to find the proxy for process {string}') do |name|
  Nonnative.pool.process_by_name(name)
rescue StandardError => e
  @error = e
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

Then('I should see a log entry of {string} in the file {string}') do |message, path|
  expect(Nonnative.log_lines(path, ->(l) { l.include?(message) }).first).to include(message)
end
