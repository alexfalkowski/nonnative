# frozen_string_literal: true

require 'socket'
require 'timeout'

require 'cucumber'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/configuration'
require 'nonnative/cucumber'

module Nonnative
  class << self
    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration if block_given?
    end

    def start
      @child_pid = spawn(configuration.process)
      return if port_open?

      stop
      raise Nonnative::Error, 'Could not start the process'
    end

    def stop
      Process.kill('SIGHUP', @child_pid)
    end

    private

    def port_open?
      Timeout.timeout(configuration.timeout) do
        TCPSocket.new('127.0.0.1', configuration.port).close
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep 0.01
        retry
      end
    rescue Timeout::Error
      false
    end
  end
end
