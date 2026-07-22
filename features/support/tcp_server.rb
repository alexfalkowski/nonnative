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

    class UnresponsiveTCPServer < Nonnative::Server
      def initialize(service)
        super

        @socket_server = ::TCPServer.new(service.host, service.port)
        @client_sockets = []
        @sockets_mutex = Mutex.new
      end

      def perform_start
        loop do
          client_socket = socket_server.accept
          add_client_socket(client_socket)
          client_socket.read
          remove_client_socket(client_socket)
          client_socket.close
        end
      rescue IOError, Errno::EBADF
        close_socket_server
      end

      def perform_stop
        close_socket_server
        close_client_sockets
      end

      private

      attr_reader :socket_server, :client_sockets, :sockets_mutex

      def add_client_socket(socket)
        sockets_mutex.synchronize { client_sockets << socket }
      end

      def remove_client_socket(socket)
        sockets_mutex.synchronize { client_sockets.delete(socket) }
      end

      def close_socket_server
        socket_server.close unless socket_server.closed?
      end

      def close_client_sockets
        sockets_mutex.synchronize do
          client_sockets.each { |socket| socket.close unless socket.closed? }
          client_sockets.clear
        end
      end
    end
  end
end
