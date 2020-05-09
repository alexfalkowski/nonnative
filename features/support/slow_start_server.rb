# frozen_string_literal: true

module Nonnative
  module Features
    class SlowStartServer < Nonnative::Server
      def perform_start
        sleep 2
      end

      def perform_stop
        # Do nothing
      end
    end
  end
end
