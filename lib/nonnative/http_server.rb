# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(app, service)
      log = File.open(service.log, 'a')
      options = {
        log_writer: Puma::LogWriter.new(log, log),
        force_shutdown_after: service.timeout
      }
      @server = Puma::Server.new(app, Puma::Events.new, options)

      super(service)
    end

    protected

    def perform_start
      server.add_tcp_listener proxy.host, proxy.port
      server.run false
    end

    def perform_stop
      server.graceful_shutdown
    end

    private

    attr_reader :queue, :server
  end
end
