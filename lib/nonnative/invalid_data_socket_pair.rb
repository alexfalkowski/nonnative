# frozen_string_literal: true

module Nonnative
  class InvalidDataSocketPair < SocketPair
    def write(socket, data)
      data = data.chars.shuffle.join

      super
    end
  end
end
