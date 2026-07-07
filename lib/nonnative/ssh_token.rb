# frozen_string_literal: true

module Nonnative
  # Generates go-service style SSH tokens for authenticating against services under test.
  #
  # Despite the name this is not an SSH protocol signature: the key is loaded from an OpenSSH-format
  # Ed25519 private key and used as a raw Ed25519 key, matching go-service's SSH token scheme. The token
  # is `<base64(claims)>.<base64(signature)>`, where the signature is a raw Ed25519 signature over the
  # claims JSON. Claims are ver/kid/sub/aud/iat/exp, with `sub == kid == key` and `iat`/`exp` in Unix
  # nanoseconds. `issuer` and `sub` are accepted for a uniform interface with the other kinds but unused:
  # SSH tokens have no issuer, and the subject is always the key id.
  #
  # @example
  #   ssh = Nonnative::SshToken.new(key: 'key-1', private_key: 'config/id_ed25519', expiration: 3600)
  #   ssh.generate(aud: 'GET /v1/things', sub: 'user-1')
  #
  # @see https://github.com/github/ssh_data ssh_data
  class SshToken
    # The go-service SSH token format version.
    TOKEN_VERSION = 'v1'

    # @param key [String] the key id; also used as the subject
    # @param private_key [String] path to an OpenSSH-format Ed25519 private key file
    # @param expiration [Integer] token lifetime in seconds (drives `exp`)
    def initialize(key:, private_key:, expiration:, **)
      @key = key
      @private_key = private_key
      @expiration = expiration
    end

    # Generates a signed SSH token.
    #
    # @param aud [String] the `aud` claim (for example `"GET /v1/things"` or a gRPC full method)
    # @return [String] the token, `"<base64(claims)>.<base64(signature)>"`
    def generate(aud:, **)
      now = Time.now
      issued_at = (now.to_i * 1_000_000_000) + now.nsec
      claims = {
        ver: TOKEN_VERSION,
        kid: @key,
        sub: @key,
        aud: aud,
        iat: issued_at,
        exp: issued_at + (@expiration * 1_000_000_000)
      }.to_json

      signature = Ed25519::SigningKey.new(seed).sign(claims)

      "#{Base64.strict_encode64(claims)}.#{Base64.strict_encode64(signature)}"
    end

    private

    def seed
      SSHData::PrivateKey.parse_openssh(File.read(@private_key)).first.sk[0, 32]
    end
  end
end
