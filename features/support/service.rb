# frozen_string_literal: true

Before('@service') do
  @service_pid = spawn('nc -k -l 30000')
end

After('@service') do
  Process.kill(9, @service_pid)
end

module Nonnative
  module Features
    class Service
      def initialize(port)
        @socket = TCPSocket.open('localhost', port)
      end

      def closed?
        @socket.closed?
      end

      def receive
        @socket.gets
      rescue StandardError => e
        e
      end
    end
  end
end
