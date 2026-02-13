# frozen_string_literal: true

module Nonnative
  # Puma-based HTTP server runner.
  #
  # This is a convenience server implementation for running a Rack/Sinatra application in-process
  # under Nonnative's server lifecycle. It binds to the configured proxy `host`/`port` (so it works
  # consistently with proxy configuration) and uses Puma for HTTP serving.
  #
  # The server is started and stopped by {Nonnative::Server} via {#perform_start} / {#perform_stop}.
  #
  # @example Running a Sinatra app
  #   app = Sinatra.new do
  #     get('/hello') { 'Hello World!' }
  #   end
  #
  #   Nonnative.configure do |config|
  #     config.server do |s|
  #       s.name = 'http'
  #       s.klass = ->(service) { Nonnative::HTTPServer.new(app, service) }
  #       s.timeout = 2
  #       s.host = '127.0.0.1'
  #       s.port = 4567
  #       s.log = 'http.log'
  #     end
  #   end
  #
  # Note: In YAML configuration you typically set `class` to a concrete subclass that calls `super(app, service)`.
  #
  # @see Nonnative::Server
  class HTTPServer < Nonnative::Server
    # Creates a Puma server for the given Rack app and runner configuration.
    #
    # @param app [#call] a Rack-compatible application (e.g. Sinatra/Rack app)
    # @param service [Nonnative::ConfigurationServer] server configuration
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

    # Binds the Puma server and begins serving.
    #
    # The listener binds to the proxy host/port so that enabling a proxy results in traffic and
    # readiness checks consistently targeting the proxy endpoint.
    #
    # @return [void]
    def perform_start
      server.add_tcp_listener proxy.host, proxy.port
      server.run false
    end

    # Gracefully shuts down the Puma server.
    #
    # @return [void]
    def perform_stop
      server.graceful_shutdown
    end

    private

    attr_reader :queue, :server
  end
end
