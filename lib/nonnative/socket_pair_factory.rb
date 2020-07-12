# frozen_string_literal: true

module Nonnative
  class SocketPairFactory
    class << self
      def create(type, proxy, logger)
        pair = case type
               when :close_all
                 CloseAllSocketPair
               when :delay
                 DelaySocketPair
               when :invalid_data
                 InvalidDataSocketPair
               else
                 SocketPair
               end

        pair.new(proxy, logger)
      end
    end
  end
end
