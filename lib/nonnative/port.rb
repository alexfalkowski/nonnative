# frozen_string_literal: true

module Nonnative
  # Performs TCP port readiness/shutdown checks for a configured runner.
  #
  # Nonnative uses this to decide whether a process/server is ready after start, and whether it has
  # shut down after stop. The checks repeatedly attempt to open a TCP connection to `process.host`
  # and `process.port` until either:
  #
  # - the expected condition is met, or
  # - the configured timeout elapses (in which case the method returns `false`)
  #
  # The `process` argument is a runner configuration object (e.g. {Nonnative::ConfigurationProcess}
  # or {Nonnative::ConfigurationServer}) that responds to `host`, `port`, and `timeout`.
  #
  # @see Nonnative::Pool for how these checks are orchestrated during start/stop
  class Port
    # @param process [#host, #port, #timeout] runner configuration providing connection details
    def initialize(process)
      @process = process
      @timeout = Nonnative::Timeout.new(process.timeout)
    end

    # Returns whether the configured host/port becomes connectable before the timeout elapses.
    #
    # This method retries on common connection errors until either a connection succeeds
    # (returns `true`) or the timeout elapses (returns `false`).
    #
    # @return [Boolean] `true` if the port opened in time; otherwise `false`
    def open?
      Nonnative.logger.info "checking if port '#{process.port}' is open on host '#{process.host}'"

      timeout.perform do
        open_socket
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep_interval
        retry
      end
    end

    # Returns whether the configured host/port becomes non-connectable before the timeout elapses.
    #
    # This method treats a successful connection as “not closed yet” and keeps retrying until it
    # observes connection failure (returns `true`) or the timeout elapses (returns `false`).
    #
    # @return [Boolean] `true` if the port closed in time; otherwise `false`
    def closed?
      Nonnative.logger.info "checking if port '#{process.port}' is closed on host '#{process.host}'"

      timeout.perform do
        open_socket
        raise Nonnative::Error
      rescue Nonnative::Error
        sleep_interval
        retry
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET
        true
      end
    end

    private

    attr_reader :process, :timeout

    def open_socket
      TCPSocket.new(process.host, process.port).close
    end

    def sleep_interval
      sleep 0.01
    end
  end
end
