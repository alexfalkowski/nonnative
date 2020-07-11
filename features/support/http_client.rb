# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def hello_get
        get('hello', { content_type: :json, accept: :json }, 1)
      end

      def hello_post
        post('hello',  'Hello World!', { content_type: :json, accept: :json }, 1)
      end

      def hello_put
        put('hello', 'Hello World!', { content_type: :json, accept: :json }, 1)
      end

      def hello_delete
        delete('hello', { content_type: :json, accept: :json }, 1)
      end

      def not_found
        get('notfound', { content_type: :json, accept: :json }, 1)
      end
    end
  end
end
