# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module NetworkChecks
        def port_closed?(port)
          socket = TCPSocket.new('127.0.0.1', port)
          socket.close

          false
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          true
        end

        def connection_error?(response)
          response.nil? || response.is_a?(IOError) || response.is_a?(SystemCallError)
        end
      end
    end
  end
end
