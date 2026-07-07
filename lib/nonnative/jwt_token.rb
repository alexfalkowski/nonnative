# frozen_string_literal: true

module Nonnative
  # Generates Ed25519 (EdDSA) JWT tokens for authenticating against services under test.
  #
  # The key id is set in the JWT `kid` header, and the claims match the common
  # iss/aud/sub/iat/nbf/exp/jti set expected by verifiers such as go-service.
  #
  # @example
  #   jwt = Nonnative::JwtToken.new(issuer: 'iss', key: 'key-1', private_key: 'config/ed25519.pem', expiration: 3600)
  #   jwt.generate(aud: 'GET /v1/things', sub: 'user-1')
  #
  # @see https://github.com/jwt/ruby-jwt-eddsa jwt-eddsa
  class JwtToken
    # @param issuer [String] the `iss` claim
    # @param key [String] the key id set in the JWT `kid` header
    # @param private_key [String] path to a PKCS#8 Ed25519 private key PEM file
    # @param expiration [Integer] token lifetime in seconds (drives `exp`)
    def initialize(issuer:, key:, private_key:, expiration:)
      @issuer = issuer
      @key = key
      @ed25519 = Nonnative::Ed25519Key.new(private_key)
      @expiration = expiration
    end

    # Generates a signed EdDSA JWT.
    #
    # @param aud [String] the `aud` claim (for example `"GET /v1/things"` or a gRPC full method)
    # @param sub [String] the `sub` claim
    # @return [String] the signed JWT
    def generate(aud:, sub:)
      now = Time.now.to_i
      payload = {
        iss: @issuer,
        aud: aud,
        sub: sub,
        iat: now,
        nbf: now,
        exp: now + @expiration,
        jti: SecureRandom.uuid
      }

      JWT.encode(payload, Ed25519::SigningKey.new(@ed25519.seed), 'EdDSA', { kid: @key })
    end
  end
end
