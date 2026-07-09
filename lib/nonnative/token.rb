# frozen_string_literal: true

module Nonnative
  # Builds signed tokens (JWT, PASETO, or SSH) for authenticating against services under test.
  #
  # The consumer passes in the signing parameters they parsed from their own configuration; this class
  # is not coupled to any particular service's configuration format. The generated token string is
  # ready to pass to {Nonnative::Header.auth_bearer}.
  #
  # @example JWT
  #   token = Nonnative::Token.new(kind: 'jwt', issuer: 'iss', key: 'key-1',
  #                                private_key: 'config/ed25519.pem', expiration: 3600)
  #   header = Nonnative::Header.auth_bearer(token.generate(aud: 'GET /v1/things', sub: 'user-1'))
  #
  # @example PASETO
  #   token = Nonnative::Token.new(kind: 'paseto', issuer: 'iss', key: 'key-1',
  #                                private_key: 'config/ed25519.pem', expiration: 3600)
  #   token.generate(aud: Nonnative::Token.grpc_audience('/health.v1.Health/Check'), sub: 'user-1')
  #
  # @see Nonnative::Header.auth_bearer
  class Token
    # Supported token kinds mapped to their implementation.
    KINDS = { 'jwt' => Nonnative::JwtToken, 'paseto' => Nonnative::PasetoToken, 'ssh' => Nonnative::SshToken }.freeze

    class << self
      # Builds the audience string for an HTTP endpoint.
      #
      # @param method [String] HTTP method (for example `"GET"`)
      # @param path [String] request path (for example `"/v1/things"`)
      # @return [String] the audience string (for example `"GET /v1/things"`)
      def http_audience(method, path)
        "#{method} #{path}"
      end

      # Builds the audience string for a gRPC endpoint.
      #
      # @param full_method [String] the gRPC full method (for example `"/health.v1.Health/Check"`)
      # @return [String] the audience string
      def grpc_audience(full_method)
        full_method
      end
    end

    # @param kind [String] token kind, one of `"jwt"`, `"paseto"`, or `"ssh"`
    # @param issuer [String] the `iss` claim (unused by the `ssh` kind)
    # @param key [String] the key id (JWT `kid` header, PASETO `kid` footer, or SSH `kid` claim)
    # @param private_key [String] path to the Ed25519 private key file (PKCS#8 PEM for `jwt`/`paseto`, OpenSSH format for `ssh`)
    # @param expiration [Integer] token lifetime in seconds (drives `exp`)
    # @raise [ArgumentError] if the kind is not supported
    def initialize(kind:, issuer:, key:, private_key:, expiration:)
      klass = KINDS.fetch(kind) { raise ArgumentError, "Unsupported token kind '#{kind}'" }
      @token = klass.new(issuer: issuer, key: key, private_key: private_key, expiration: expiration)
    end

    # Generates a signed token.
    #
    # The optional time claims default to the current time (and the constructor `expiration`), so
    # omitting them reproduces the token's normal claims. Supply them to mint tokens with specific
    # time claims for negative auth tests, such as a not-yet-valid (future `not_before`) or
    # clock-skewed token. Times are absolute; the `ssh` kind has no `nbf` claim and rejects
    # `not_before`.
    #
    # @param aud [String] the `aud` claim
    # @param sub [String] the `sub` claim
    # @param issued_at [Time, nil] overrides the `iat` claim (default: now)
    # @param not_before [Time, nil] overrides the `nbf` claim (default: `issued_at`); unsupported by `ssh`
    # @param expires_at [Time, nil] overrides the `exp` claim (default: `issued_at` plus `expiration`)
    # @return [String] the signed token
    def generate(aud:, sub:, issued_at: nil, not_before: nil, expires_at: nil)
      @token.generate(aud: aud, sub: sub, issued_at: issued_at, not_before: not_before, expires_at: expires_at)
    end
  end
end
