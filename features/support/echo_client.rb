# frozen_string_literal: true

module Nonnative
  class EchoClient
    def initialize(port)
      @port = port
    end

    def request(msg)
      s = TCPSocket.open('127.0.0.1', @port)
      s.puts msg
      response = s.gets.chomp
      s.close
      response
    end
  end
end
