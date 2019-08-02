# frozen_string_literal: true

module Nonnative
  class Process
    def initialize(configuration)
      @configuration = configuration
    end

    def start
      @pid = spawn(configuration.process)
      [port_open?, pid]
    end

    def stop
      ::Process.kill('SIGHUP', pid)
      [port_closed?, pid]
    end

    private

    attr_reader :configuration, :pid

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
