# frozen_string_literal: true

module Nonnative
  # Puma-based HTTP server runner.
  #
  # This is a convenience server implementation for running an HTTP service in-process under
  # Nonnative's server lifecycle. It binds to the configured server `host` and first `ports` entry.
  #
  # The server is started and stopped by {Nonnative::Server} via {#perform_start} / {#perform_stop}.
  #
  # @example Running an HTTP service
  #   class HelloHTTPService < Nonnative::HTTPService
  #     get('/hello') { 'Hello World!' }
  #   end
  #
  #   class HelloHTTPServer < Nonnative::HTTPServer
  #     def initialize(service)
  #       super(HelloHTTPService.new, service)
  #     end
  #   end
  #
  #   Nonnative.configure do |config|
  #     config.server do |s|
  #       s.name = 'http'
  #       s.klass = HelloHTTPServer
  #       s.timeout = 2
  #       s.host = '127.0.0.1'
  #       s.ports = [4567]
  #       s.log = 'http.log'
  #     end
  #   end
  #
  # YAML configuration uses the same concrete subclass name in its `class` field.
  #
  # @see Nonnative::Server
  class HTTPServer < Nonnative::Server
    # Creates a Puma server for the given HTTP service and runner configuration.
    #
    # @param http_service [#call, Hash<String, #call>] an HTTP service instance or `Rack::URLMap`
    #   mount map using path prefixes or host-qualified URLs
    # @param service [Nonnative::ConfigurationServer] server configuration
    # @raise [ArgumentError] if `http_service` is an empty mount map or contains an invalid mount path
    def initialize(http_service, service)
      if http_service.is_a?(Hash)
        raise ArgumentError, 'HTTP server requires at least one service mount' if http_service.empty?

        http_service = Rack::URLMap.new(http_service)
      end

      # Keep the log IO so the server lifecycle can release Puma's file handle on stop.
      @log = File.open(service.log, 'a')
      options = {
        log_writer: Puma::LogWriter.new(log, log),
        force_shutdown_after: service.timeout
      }
      @server = Puma::Server.new(http_service, Puma::Events.new, options)

      super(service)
    end

    protected

    # Binds the Puma server and begins serving.
    #
    # The listener binds to the configured server host and first configured port.
    #
    # @return [void]
    def perform_start
      server.add_tcp_listener service.host, service.port
      server.run false
    end

    # Gracefully shuts down the Puma server.
    #
    # @return [void]
    def perform_stop
      server.graceful_shutdown
    ensure
      close_log
    end

    private

    attr_reader :server, :log

    def close_log
      log.close unless log.closed?
    end
  end
end
