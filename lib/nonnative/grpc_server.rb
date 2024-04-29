# frozen_string_literal: true

module Nonnative
  class GRPCServer < Nonnative::Server
    def initialize(service)
      @server = GRPC::RpcServer.new
      server.handle(svc)

      # Unfortunately gRPC has only one logger so the first server wins.
      GRPC.define_singleton_method(:logger) do
        @logger ||= Logger.new(service.log)
      end

      super(service)
    end

    protected

    def perform_start
      server.add_http2_port("#{service.host}:#{service.port}", :this_port_is_insecure)
      server.run
    end

    def perform_stop
      server.stop
    end

    def wait_start
      timeout.perform do
        super until server.running?
      end
    end

    def wait_stop
      timeout.perform do
        super until server.stopped?
      end
    end

    private

    attr_reader :server
  end
end
