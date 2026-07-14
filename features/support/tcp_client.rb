# frozen_string_literal: true

module Nonnative
  module Features
    class TCPClient
      def initialize(host, port)
        @host = host || '127.0.0.1'
        @port = port
      end

      def connect
        socket
        self
      end

      def closed?
        @socket.nil? || @socket.closed?
      end

      def receive
        socket.gets&.chomp
      rescue StandardError => e
        e
      end

      def request(message)
        client = TCPSocket.open(@host, @port)
        client.puts message
        response = client.gets.chomp
        client.close
        response
      rescue StandardError => e
        e
      end

      def write(message)
        socket.puts(message)
      end

      def close_write
        socket.close_write
      end

      private

      attr_reader :host, :port

      def socket
        @socket ||= TCPSocket.open(host, port)
      end
    end
  end
end
