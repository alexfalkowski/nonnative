# frozen_string_literal: true

module Nonnative
  # Generates Ed25519 PASETO v4.public tokens for authenticating against services under test.
  #
  # The key id is carried in a JSON footer (`{"kid":"..."}`), and the claims match the common
  # iss/aud/sub/iat/nbf/exp/jti set expected by verifiers such as go-service. The signing library is
  # required lazily so that requiring `nonnative` does not depend on `rbnacl`/libsodium being present.
  #
  # @example
  #   paseto = Nonnative::PasetoToken.new(issuer: 'iss', key: 'key-1', private_key: 'config/ed25519.pem', expiration: 3600)
  #   paseto.generate(aud: 'GET /v1/things', sub: 'user-1')
  #
  # @see https://github.com/bannable/paseto ruby-paseto
  class PasetoToken
    # @param issuer [String] the `iss` claim
    # @param key [String] the key id carried in the `kid` footer
    # @param private_key [String] path to a PKCS#8 Ed25519 private key PEM file
    # @param expiration [Integer] token lifetime in seconds (drives `exp`)
    def initialize(issuer:, key:, private_key:, expiration:)
      @issuer = issuer
      @key = key
      @ed25519 = Nonnative::Ed25519Key.new(private_key)
      @expiration = expiration
    end

    # Generates a signed PASETO v4.public token.
    #
    # @param aud [String] the `aud` claim (for example `"GET /v1/things"` or a gRPC full method)
    # @param sub [String] the `sub` claim
    # @return [String] the signed PASETO token
    def generate(aud:, sub:)
      load_dependencies!

      now = Time.now.utc
      claims = {
        'iss' => @issuer,
        'aud' => aud,
        'sub' => sub,
        'iat' => now.iso8601,
        'nbf' => now.iso8601,
        'exp' => (now + @expiration).iso8601,
        'jti' => SecureRandom.uuid
      }

      Paseto::V4::Public.new(@ed25519.pem).encode!(claims, footer: { 'kid' => @key }.to_json)
    end

    private

    # Loads the PASETO signing libraries lazily and raises a clear error if they are unavailable.
    # rbnacl loads system libsodium at runtime, which the gemspec cannot guarantee, so requiring it
    # here keeps `require 'nonnative'` working without libsodium for consumers that do not use PASETO.
    def load_dependencies!
      require 'rbnacl'
      require 'paseto'
    rescue LoadError => e
      raise Nonnative::Error, "PASETO token generation requires libsodium and the rbnacl and ruby-paseto gems (#{e.message})"
    end
  end
end
