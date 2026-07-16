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

      # Reads raw chunks until a line terminator is seen, without buffering across calls the way
      # `gets` does, so callers can observe how many `recv` calls a fragmented response took.
      def receive_fragments
        fragments = []
        buffer = +''

        until buffer.end_with?("\n")
          chunk = socket.recv(1024)
          break if chunk.nil? || chunk.empty?

          fragments << chunk
          buffer << chunk
        end

        fragments
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
