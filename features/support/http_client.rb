# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def request
        get('hello')
      end
    end
  end
end
