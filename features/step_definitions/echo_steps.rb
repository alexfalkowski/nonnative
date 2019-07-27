# frozen_string_literal: true

When('we send {string} with the echo client') do |message|
  @response = Nonnative::EchoClient.new.request(message)
end

Then('we should receive a {string} response') do |response|
  expect(@response).to eq(response)
end
