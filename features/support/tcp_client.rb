# frozen_string_literal: true

module Nonnative
  module Features
    class TCPClient
      def initialize(host, port)
        @host = host || '127.0.0.1'
        @port = port
      end

      def request(msg)
        s = TCPSocket.open(@host, @port)
        s.puts msg
        response = s.gets.chomp
        s.close
        response
      rescue StandardError => e
        e
      end
    end
  end
end
