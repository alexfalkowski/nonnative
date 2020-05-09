# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def hello_get
        get('hello', { content_type: :json, accept: :json })
      end

      def hello_post
        post('hello', { content_type: :json, accept: :json })
      end
    end
  end
end
