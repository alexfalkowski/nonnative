# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(service)
      @server = Puma::Server.new(app, Puma::Events.strings)

      super service
    end

    protected

    def perform_start
      server.add_tcp_listener '0.0.0.0', proxy.port
      server.run.join
    end

    def perform_stop
      server.stop(true)
    end

    def wait_start
      timeout.perform do
        super until server.running
      end
    end

    def wait_stop
      timeout.perform do
        super while server.running
      end
    end

    private

    attr_reader :queue, :server
  end
end
