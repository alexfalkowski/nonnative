# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPClient < Nonnative::HTTPClient
      def hello_get
        with_retry(1, 1) do
          headers = Nonnative::Header.http_user_agent('test 1.0').merge({ content_type: :json, accept: :json })

          get('hello', { headers:, read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_post
        with_retry(1, 1) do
          headers = Nonnative::Header.auth_basic('test:test').merge({ content_type: :json, accept: :json })

          post('hello', 'Hello World!', { headers:, read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_put
        with_retry(1, 1) do
          headers = Nonnative::Header.auth_bearer('token').merge({ content_type: :json, accept: :json })

          put('hello', 'Hello World!', { headers:, read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_delete
        with_retry(1, 1) do
          delete('hello', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
        end
      end

      def not_found
        with_retry(1, 1) do
          get('notfound', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
        end
      end
    end
  end
end
