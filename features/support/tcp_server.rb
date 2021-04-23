# frozen_string_literal: true

module Nonnative
  module Features
    class TCPServer < Nonnative::Server
      def perform_start
        @socket_server = ::TCPServer.new('0.0.0.0', proxy.port)

        loop do
          client_socket = @socket_server.accept
          client_socket.puts 'Hello World!'
          client_socket.close
        end
      rescue StandardError
        @socket_server.close
      end

      def perform_stop
        @socket_server.close
      end
    end
  end
end
