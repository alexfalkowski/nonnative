# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def request
        get('hello', { content_type: :json, accept: :json })
      end
    end
  end
end
