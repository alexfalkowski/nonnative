# frozen_string_literal: true

module Nonnative
  # Loads an Ed25519 private key from a PEM file for signing tokens.
  #
  # Verifiers such as go-service use Ed25519 keys encoded as PKCS#8 PEM. This reads the PEM once and
  # exposes it in the shapes the token backends need: the raw PEM for {Nonnative::PasetoToken} and the
  # 32-byte seed for {Nonnative::JwtToken}.
  #
  # @example
  #   key = Nonnative::Ed25519Key.new('config/ed25519.pem')
  #   key.pem   # => "-----BEGIN PRIVATE KEY-----\n..."
  #   key.seed  # => 32-byte binary String
  class Ed25519Key
    # @param path [String] path to a PKCS#8 Ed25519 private key PEM file
    def initialize(path)
      @pem = File.read(path)
    end

    # @return [String] the PEM contents (PKCS#8 Ed25519 private key)
    attr_reader :pem

    # Extracts the raw 32-byte Ed25519 seed from the PEM.
    #
    # @return [String] the raw 32-byte Ed25519 seed
    def seed
      OpenSSL::PKey.read(@pem).raw_private_key
    end
  end
end
