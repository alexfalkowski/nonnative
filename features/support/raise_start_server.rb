# frozen_string_literal: true

module Nonnative
  module Features
    class RaiseStartServer < Nonnative::Server
      def perform_start
        raise StandardError, 'boom on perform_start'
      end

      def perform_stop
        # Do nothing
      end
    end
  end
end
