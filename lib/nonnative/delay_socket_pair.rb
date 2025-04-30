# frozen_string_literal: true

module Nonnative
  class DelaySocketPair < SocketPair
    def read(socket)
      Nonnative.logger.info "delaying socket '#{socket.inspect}' for 'delay' pair"

      duration = proxy.options[:delay] || 2
      sleep duration

      super
    end
  end
end
