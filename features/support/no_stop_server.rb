# frozen_string_literal: true

module Nonnative
  module Features
    class NoStopServer < Nonnative::Server
      def perform_start
        @socket_server = ::TCPServer.new(service.host, service.port)
      end

      def perform_stop
        # Do nothing
      end
    end
  end
end
