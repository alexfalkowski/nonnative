# frozen_string_literal: true

module Nonnative
  class CloseAllSocketPair < SocketPair
    def connect(local_socket)
    ensure
      local_socket.close
    end
  end
end
