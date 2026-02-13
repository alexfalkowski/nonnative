# frozen_string_literal: true

module Nonnative
  # Helper utilities for building request headers for HTTP and gRPC clients.
  #
  # This class returns Ruby hashes suitable for passing into client libraries (for example
  # RestClient for HTTP or gRPC call metadata).
  #
  # @example HTTP user-agent (RestClient style)
  #   headers = Nonnative::Header.http_user_agent('my-client/1.0')
  #   # => { user_agent: "my-client/1.0" }
  #
  # @example gRPC user-agent (metadata)
  #   metadata = Nonnative::Header.grpc_user_agent('my-client/1.0')
  #   # => { "grpc.primary_user_agent" => "my-client/1.0" }
  #
  # @example Basic auth header
  #   headers = Nonnative::Header.auth_basic('user:pass')
  #   # => { authorization: "Basic dXNlcjpwYXNz" }
  #
  # @example Bearer auth header
  #   headers = Nonnative::Header.auth_bearer('token')
  #   # => { authorization: "Bearer token" }
  #
  # @see https://github.com/rest-client/rest-client RestClient
  # @see https://grpc.io/docs/guides/concepts/ gRPC concepts (metadata)
  class Header
    class << self
      # Builds an HTTP `User-Agent` header hash.
      #
      # This uses the key style commonly used by RestClient (`user_agent:`).
      #
      # @param user_agent [String] user agent value
      # @return [Hash{Symbol=>String}] header hash containing the user agent
      def http_user_agent(user_agent)
        { user_agent: }
      end

      # Builds gRPC metadata for setting the primary user agent.
      #
      # @param user_agent [String] user agent value
      # @return [Hash{String=>String}] gRPC metadata hash
      def grpc_user_agent(user_agent)
        { 'grpc.primary_user_agent' => user_agent }
      end

      # Builds an HTTP Basic Authorization header.
      #
      # The credentials are base64-encoded using strict encoding. The `credentials` string should
      # typically be in the form `"username:password"`.
      #
      # @param credentials [String] basic auth credentials in `"user:pass"` form
      # @return [Hash{Symbol=>String}] header hash containing the Authorization header
      def auth_basic(credentials)
        { authorization: "Basic #{Base64.strict_encode64(credentials)}" }
      end

      # Builds an HTTP Bearer Authorization header.
      #
      # @param token [String] bearer token
      # @return [Hash{Symbol=>String}] header hash containing the Authorization header
      def auth_bearer(token)
        { authorization: "Bearer #{token}" }
      end
    end
  end
end
