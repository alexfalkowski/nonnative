# frozen_string_literal: true

module Nonnative
  # gRPC server runner implemented using {GRPC::RpcServer}.
  #
  # This is a convenience server implementation for running a gRPC service in-process under
  # Nonnative's server lifecycle. It binds to the configured server `host` and first `ports` entry.
  #
  # Important note about logging: the `grpc` gem uses a global logger. This implementation sets
  # `GRPC.logger` to write to the configured `service.log`, and whichever gRPC server is initialized
  # first "wins" that global logger.
  #
  # @see Nonnative::Server
  class GRPCServer < Nonnative::Server
    # Creates a gRPC server and registers the provided service handler(s).
    #
    # @param svc [Object, Array<Object>] a gRPC service implementation or a non-empty array of
    #   implementations (typically `...::Service` subclasses or instances)
    # @param service [Nonnative::ConfigurationServer] server configuration
    # @raise [ArgumentError] if `svc` is an empty array
    def initialize(svc, service)
      @server = GRPC::RpcServer.new
      handlers = svc.is_a?(Array) ? svc : [svc]
      raise ArgumentError, 'gRPC server requires at least one service handler' if handlers.empty?

      handlers.each { |handler| server.handle(handler) }

      # Unfortunately gRPC has only one logger so the first server wins.
      GRPC.define_singleton_method(:logger) do
        @logger ||= Logger.new(service.log)
      end

      super(service)
    end

    protected

    # Binds the gRPC server and begins serving requests.
    #
    # The server binds to the configured server host and first configured port.
    #
    # @return [void]
    def perform_start
      server.add_http2_port("#{service.host}:#{service.port}", :this_port_is_insecure)
      server.run
    end

    # Stops the gRPC server.
    #
    # @return [void]
    def perform_stop
      server.stop
    end

    # Waits until the gRPC server reports it is running, or the configured timeout elapses.
    #
    # @return [Object, false] the last evaluated expression from the timeout block, or `false` on timeout
    def wait_start
      timeout.perform do
        super until server.running?
      end
    end

    # Waits until the gRPC server reports it has stopped, or the configured timeout elapses.
    #
    # @return [Object, false] the last evaluated expression from the timeout block, or `false` on timeout
    def wait_stop
      timeout.perform do
        super until server.stopped?
      end
    end

    private

    attr_reader :server
  end
end
