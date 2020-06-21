# frozen_string_literal: true

module Nonnative
  class GRPCServer < Nonnative::Server
    def initialize(service)
      @server = GRPC::RpcServer.new

      super service
    end

    def configure(grpc)
      # Classes will add configuration
    end

    protected

    def perform_start
      server.add_http2_port("0.0.0.0:#{proxy.port}", :this_port_is_insecure)
      configure server

      server.run

      super
    end

    def perform_stop
      server.stop

      super
    end

    def wait_start
      server.wait_till_running(service.timeout)
    end

    private

    attr_reader :server
  end
end
