# frozen_string_literal: true

module Nonnative
  module Features
    class TCPServer < Nonnative::Server
      def initialize(service)
        super

        @socket_server = ::TCPServer.new(service.host, service.port)
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

    class CleanupServer < TCPServer
      CLEANUP_DELAY = 0.3

      def initialize(service)
        super

        @cleanup_complete = false
      end

      def cleanup_complete?
        @cleanup_complete
      end

      def perform_start
        super
      ensure
        sleep CLEANUP_DELAY
        @cleanup_complete = true
      end
    end

    # Binds a fresh socket per perform_start call, rather than once in the constructor like
    # TCPServer, so a scenario can verify the server actually listens again after being restarted.
    class RestartableServer < Nonnative::Server
      STOP_DELAY = 0.3

      def perform_start
        @socket_server = ::TCPServer.new(service.host, service.port)
        loop { socket_server.accept.close }
      rescue StandardError
        socket_server&.close
      ensure
        sleep STOP_DELAY
      end

      def perform_stop
        socket_server&.close
      end

      private

      attr_reader :socket_server
    end
  end
end
