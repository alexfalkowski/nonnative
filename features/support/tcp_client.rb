# frozen_string_literal: true

module Nonnative
  module Features
    class TCPClient
      def initialize(port)
        @port = port
      end

      def request(msg)
        s = TCPSocket.open('0.0.0.0', @port)
        s.puts msg
        response = s.gets.chomp
        s.close
        response
      end
    end
  end
end
