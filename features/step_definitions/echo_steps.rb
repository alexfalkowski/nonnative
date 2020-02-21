# frozen_string_literal: true

When('we send {string} with the echo client') do |message|
  @responses = []
  @responses << Nonnative::EchoClient.new(12_321).request(message)
  @responses << Nonnative::EchoClient.new(12_322).request(message)
end

Then('we should receive a {string} response') do |response|
  @responses.each { |r| expect(r).to eq(response) }
end
