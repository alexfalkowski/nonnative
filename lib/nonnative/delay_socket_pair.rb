# frozen_string_literal: true

module Nonnative
  class DelaySocketPair < SocketPair
    def read(socket)
      sleep 2

      super socket
    end
  end
end
