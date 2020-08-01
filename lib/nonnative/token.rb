# frozen_string_literal: true

module Nonnative
  class Token
    def decode(bearer)
      token = bearer.split(' ').last
      JWT.decode(token, nil, false, { algorithm: 'RS256' }).first
    end
  end
end
