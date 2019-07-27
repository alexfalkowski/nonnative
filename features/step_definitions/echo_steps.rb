# frozen_string_literal: true

Given('we start the echo server') do
  @child_pid = spawn 'features/support/bin/start'
  sleep 1
end

When('we send {string} with the echo client') do |message|
  @response = Nonnative::EchoClient.new.request(message)
end

Then('we should receive a {string} response') do |response|
  expect(@response).to eq(response)
  Process.kill('SIGHUP', @child_pid)
end
