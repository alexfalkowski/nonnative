# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def hello_get
        get('hello', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
      end

      def hello_post
        post('hello', 'Hello World!', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
      end

      def hello_put
        put('hello', 'Hello World!',  { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
      end

      def hello_delete
        delete('hello', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
      end

      def not_found
        get('notfound', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
      end
    end
  end
end
