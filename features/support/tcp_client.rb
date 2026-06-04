# frozen_string_literal: true

module Nonnative
  module Features
    class TCPClient
      def initialize(host, port)
        @host = host || '127.0.0.1'
        @port = port
      end

      def request(message)
        socket = TCPSocket.open(@host, @port)
        socket.puts message
        response = socket.gets.chomp
        socket.close
        response
      rescue StandardError => e
        e
      end
    end
  end
end
