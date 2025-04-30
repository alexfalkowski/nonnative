# frozen_string_literal: true

module Nonnative
  class InvalidDataSocketPair < SocketPair
    def write(socket, data)
      Nonnative.logger.info "shuffling socket data '#{socket.inspect}' for 'invalid_data' pair"

      data = data.chars.shuffle.join

      super
    end
  end
end
