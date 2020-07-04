# frozen_string_literal: true

module Nonnative
  class GRPCServer < Nonnative::Server
    def initialize(service)
      @server = GRPC::RpcServer.new
      server.handle(svc)

      super service
    end

    protected

    def perform_start
      server.add_http2_port("0.0.0.0:#{proxy.port}", :this_port_is_insecure)
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
