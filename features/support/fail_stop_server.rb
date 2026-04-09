# frozen_string_literal: true

require_relative 'tcp_server'

module Nonnative
  module Features
    class FailStopServer < Nonnative::Features::TCPServer
      def stop
        super

        raise StandardError, 'boom on stop'
      end
    end
  end
end
