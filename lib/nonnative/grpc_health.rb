# frozen_string_literal: true

module Nonnative
  # Client helper for the standard gRPC health checking protocol over an insecure plaintext channel.
  # An empty or nil service name checks overall server health.
  class GRPCHealth
    NETWORK_ERRORS = [
      GRPC::BadStatus,
      GRPC::Core::CallError
    ].freeze

    # @param host [String] gRPC server host
    # @param port [Integer] gRPC server port
    # @param service [String, nil] gRPC health service name, or empty/nil for overall server health
    # @param timeout [Numeric] default call timeout in seconds
    def initialize(host:, port:, service:, timeout: 1)
      @host = host
      @port = port
      @service = service.to_s
      @timeout = timeout
    end

    # Calls the gRPC health check endpoint.
    #
    # gRPC status and network failures are propagated to the caller.
    #
    # @param deadline [Time] gRPC deadline
    # @return [Grpc::Health::V1::HealthCheckResponse]
    def check(deadline: Time.now + timeout)
      stub.check(request, deadline: deadline)
    end

    # Returns true when the gRPC health endpoint reports SERVING.
    #
    # Returns `false` for non-SERVING responses and gRPC status/network failures.
    #
    # @param deadline [Time] gRPC deadline
    # @return [Boolean]
    def serving?(deadline: Time.now + timeout)
      check(deadline: deadline).status == :SERVING
    rescue *NETWORK_ERRORS
      false
    end

    # Returns the checked gRPC health endpoint for lifecycle diagnostics.
    #
    # @return [String]
    def endpoint
      service.empty? ? "grpc://#{host}:#{port}" : "grpc://#{host}:#{port}/#{service}"
    end

    private

    attr_reader :host, :port, :service, :timeout

    def request
      Grpc::Health::V1::HealthCheckRequest.new(service: service)
    end

    def stub
      @stub ||= Grpc::Health::V1::Health::Stub.new("#{host}:#{port}", :this_channel_is_insecure)
    end
  end
end
