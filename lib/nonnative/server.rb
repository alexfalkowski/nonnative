# frozen_string_literal: true

module Nonnative
  # Runtime runner that manages an in-process Ruby server.
  #
  # A server runner:
  # - starts the configured proxy (if any),
  # - starts a Ruby thread that runs {#perform_start},
  # - waits briefly (via the runner `wait`), and
  # - participates in readiness/shutdown via TCP port checks orchestrated by {Nonnative::Pool}.
  #
  # Concrete server implementations are expected to subclass {Nonnative::Server} and implement:
  # - {#perform_start} (to bind/listen and begin serving), and
  # - {#perform_stop} (to gracefully shut down).
  #
  # The underlying configuration is a {Nonnative::ConfigurationServer}.
  #
  # @see Nonnative::ConfigurationServer
  # @see Nonnative::Pool
  class Server < Runner
    # @param service [Nonnative::ConfigurationServer] server configuration
    def initialize(service)
      super

      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    # Starts the proxy (if any) and starts the server thread if not already started.
    #
    # @return [Array<(Integer, TrueClass)>]
    #   a tuple of:
    #   - a stable identifier for this server instance (`object_id`)
    #   - `true` (thread creation itself is considered started; readiness is checked separately)
    def start
      unless thread
        proxy.start
        @thread = Thread.new { perform_start }

        wait_start

        Nonnative.logger.info "started server '#{service.name}'"
      end

      [object_id, true]
    end

    # Stops the server if it is running.
    #
    # Calls {#perform_stop}, terminates the server thread, stops the proxy (if any), and waits briefly.
    #
    # @return [Integer] the server identifier (`object_id`)
    def stop
      if thread
        perform_stop
        thread.terminate
        proxy.stop

        @thread = nil
        wait_stop

        Nonnative.logger.info "stopped server '#{service.name}'"
      end

      object_id
    end

    private

    attr_reader :thread, :timeout
  end
end
