# frozen_string_literal: true

module Nonnative
  class CloseAllSocketPair < SocketPair
    def connect(local_socket)
      Nonnative.logger.info "closing socket '#{local_socket.inspect}' for 'close_all' pair"

      local_socket.close
    end
  end
end
