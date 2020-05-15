# frozen_string_literal: true

module Nonnative
  class GRPCServer < Nonnative::Server
    def initialize(service)
      @server = GRPC::RpcServer.new

      server.add_http2_port("0.0.0.0:#{service.port}", :this_port_is_insecure)
      configure server

      super service
    end

    def configure(grpc)
      # Classes will add configuration
    end

    def perform_start
      server.run
    end

    def perform_stop
      server.stop
    end

    protected

    def wait_start
      server.wait_till_running(service.timeout)
    end

    private

    attr_reader :server
  end
end
