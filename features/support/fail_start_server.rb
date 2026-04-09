# frozen_string_literal: true

module Nonnative
  module Features
    class FailStartServer < Nonnative::Server
      def start
        raise StandardError, 'boom on start'
      end

      def perform_start
        # Do nothing
      end

      def perform_stop
        # Do nothing
      end
    end
  end
end
