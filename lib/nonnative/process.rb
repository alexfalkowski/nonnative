# frozen_string_literal: true

module Nonnative
  class Process
    def initialize(definition)
      @definition = definition
    end

    def start
      @pid = if definition.file
               spawn(definition.process, %i[out err] => [definition.file, 'a'])
             else
               spawn(definition.process)
             end

      [port_open?, pid]
    end

    def stop
      ::Process.kill('SIGINT', pid)
      [port_closed?, pid]
    end

    private

    attr_reader :definition, :pid

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
      Timeout.timeout(definition.timeout) do
        yield
      end
    rescue Timeout::Error
      false
    end

    def open_socket
      TCPSocket.new('127.0.0.1', definition.port).close
    end

    def sleep_interval
      sleep 0.01
    end
  end
end
