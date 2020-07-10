# frozen_string_literal: true

module Nonnative
  class SocketPairFactory
    class << self
      def create(type, port)
        case type
        when :close_all
          CloseSocketPair.new(port)
        when :delay
          DelaySocketPair.new(port)
        else
          SocketPair.new(port)
        end
      end
    end
  end
end
