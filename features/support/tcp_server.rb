# frozen_string_literal: true

module Nonnative
  module Features
    class TCPServer < Nonnative::Server
      def initialize(service)
        super

        @socket_server = ::TCPServer.new(proxy.host, proxy.port)
      end

      def perform_start
        loop do
          client_socket = socket_server.accept
          client_socket.puts 'Hello World!'
          client_socket.close
        end
      rescue StandardError
        socket_server.close
      end

      def perform_stop
        socket_server.close
      end

      private

      attr_reader :socket_server
    end
  end
end
