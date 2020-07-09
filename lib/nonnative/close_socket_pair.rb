# frozen_string_literal: true

module Nonnative
  class CloseSocketPair < SocketPair
    def connect(local_socket)
      local_socket.close
    end
  end
end
