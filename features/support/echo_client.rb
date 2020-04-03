# frozen_string_literal: true

module Nonnative
  class EchoClient
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
