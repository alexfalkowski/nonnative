# frozen_string_literal: true

Given('an Ed25519 private key') do
  @signing_material = ed25519_pem
  @private_key_path = write_key_file(@signing_material)
end

Given('an OpenSSH Ed25519 private key') do
  @private_key_path = openssh_ed25519_key
  @signing_material = File.read(@private_key_path)
end

When('I generate a {string} token for {string} as {string}') do |kind, aud, sub|
  generate_token(kind, aud, sub)
end

When('I generate a {string} token for the {string} {string} endpoint as {string}') do |kind, method, path, sub|
  generate_token(kind, Nonnative::Token.http_audience(method, path), sub)
end

When('I generate a {string} token for the {string} method as {string}') do |kind, full_method, sub|
  generate_token(kind, Nonnative::Token.grpc_audience(full_method), sub)
end

Then('the token should be verifiable with:') do |table|
  claims, kid = decoded_token(@kind, @token, @signing_material)

  table.rows_hash.each do |field, expected|
    expect(field == 'kid' ? kid : claims[field]).to eq(expected)
  end
end
