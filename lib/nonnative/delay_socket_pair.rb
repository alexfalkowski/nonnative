# frozen_string_literal: true

module Nonnative
  class DelaySocketPair < SocketPair
    def read(socket)
      duration = proxy.options[:delay] || 2
      sleep duration

      super(socket)
    end
  end
end
