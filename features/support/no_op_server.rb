# frozen_string_literal: true

module Nonnative
  module Features
    class NoOpServer < Nonnative::Server
      def perform_start
        # Do nothing
      end

      def perform_stop
        # Do nothing
      end
    end
  end
end
