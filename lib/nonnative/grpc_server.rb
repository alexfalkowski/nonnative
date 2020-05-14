# frozen_string_literal: true

module Nonnative
  class GRPCServer < Nonnative::Server
    def initialize(port, timeout)
      @server = GRPC::RpcServer.new

      server.add_http2_port("0.0.0.0:#{port}", :this_port_is_insecure)
      server.wait_till_running(timeout)
      configure server

      super port, timeout
    end

    def configure(grpc)
      # Classes will add configuration
    end

    def perform_start
      server.run_till_terminated
    end

    def perform_stop
      server.stop
    end

    private

    attr_reader :server
  end
end
