# frozen_string_literal: true

require 'socket'

module Nonnative
  class EchoClient
    def initialize(host = '127.0.0.1', port = 12_321)
      @host = host
      @port = port
    end

    def request(msg)
      s = TCPSocket.open(@host, @port)
      s.puts msg
      response = s.gets.chomp
      s.close
      response
    end
  end
end
