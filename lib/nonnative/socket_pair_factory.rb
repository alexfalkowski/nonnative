# frozen_string_literal: true

module Nonnative
  class SocketPairFactory
    class << self
      def create(kind, proxy)
        pair = case kind
               when :close_all
                 CloseAllSocketPair
               when :delay
                 DelaySocketPair
               when :invalid_data
                 InvalidDataSocketPair
               else
                 SocketPair
               end

        pair.new(proxy)
      end
    end
  end
end
