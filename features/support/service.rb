# frozen_string_literal: true

Before('@service') do
  @service_fixture = Nonnative::Features::ServiceFixture.new('127.0.0.1', 30_000)
  @service_fixture.start
end

After('@service') do
  @service_fixture&.stop
end

module Nonnative
  module Features
    class ServiceFixture
      def initialize(host, port)
        @server = ::TCPServer.new(host, port)
        @clients = []
        @threads = []
        @mutex = Mutex.new
      end

      def start
        @thread = Thread.new { accept_connections }
      end

      def stop
        close_server
        close_clients
        join_threads
      end

      private

      attr_reader :server, :clients, :threads, :mutex, :thread

      def accept_connections
        loop do
          client = server.accept
          mutex.synchronize { clients << client }
          threads << Thread.new(client) { |socket| read_until_closed(socket) }
        end
      rescue IOError, Errno::EBADF
        nil
      end

      def read_until_closed(socket)
        while (line = socket.gets)
          socket.puts(line)
        end
      rescue IOError, SystemCallError
        nil
      ensure
        close_socket(socket)
      end

      def close_server
        server.close unless server.closed?
      end

      def close_clients
        mutex.synchronize { clients.each { |client| close_socket(client) } }
      end

      def join_threads
        thread&.join
        threads.each(&:join)
      end

      def close_socket(socket)
        socket.close unless socket.closed?
      rescue IOError
        nil
      end
    end
  end
end
