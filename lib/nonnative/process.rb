# frozen_string_literal: true

module Nonnative
  class Process
    def initialize(configuration, logger)
      @configuration = configuration
      @logger = logger
    end

    def start
      @child_pid = spawn(configuration.process)
      return if port_open?

      logger.error('Process has started though did respond in time', pid: child_pid)
    end

    def stop
      ::Process.kill('SIGHUP', child_pid)
      return if port_closed?

      logger.error('Process has stopped though did respond in time', pid: child_pid)
    end

    private

    attr_reader :configuration, :logger, :child_pid

    def port_open?
      timeout do
        open_socket
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep_interval
        retry
      end
    end

    def port_closed?
      timeout do
        open_socket
        raise Nonnative::Error
      rescue Nonnative::Error
        sleep_interval
        retry
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        true
      end
    end

    def timeout
      Timeout.timeout(configuration.timeout) do
        yield
      end
    rescue Timeout::Error
      false
    end

    def open_socket
      TCPSocket.new('127.0.0.1', configuration.port).close
    end

    def sleep_interval
      sleep 0.01
    end
  end
end
