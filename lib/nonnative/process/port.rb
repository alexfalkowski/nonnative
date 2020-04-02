# frozen_string_literal: true

module Nonnative
  module Process
    class Port
      def initialize(process)
        @process = process
        @timeout = Nonnative::Timeout.new(process.timeout)
      end

      def open?
        timeout.perform do
          open_socket
          true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep_interval
          retry
        end
      end

      def closed?
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
        TCPSocket.new('127.0.0.1', process.port).close
      end

      def sleep_interval
        sleep 0.01
      end
    end
  end
end
