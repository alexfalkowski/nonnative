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

      def response_metadata
        with_retry(1, 1) do
          get('response-metadata', { read_timeout: 1, open_timeout: 1 })
        end
      end

      def mounted_get
        with_retry(1, 1) do
          get('mounted/hello', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
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

      def hello_patch
        with_retry(1, 1) do
          headers = Nonnative::Header.http_user_agent('test 1.0').merge({ content_type: :json, accept: :json })

          patch('hello', 'Hello World!', { headers:, read_timeout: 1, open_timeout: 1 })
        end
      end

      def patch_not_found
        with_retry(1, 1) do
          patch('notfound', 'Hello World!', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_delete
        with_retry(1, 1) do
          delete('hello', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_head
        with_retry(1, 1) do
          head('hello', { read_timeout: 1, open_timeout: 1 })
        end
      end

      def hello_options
        with_retry(1, 1) do
          options('hello', { read_timeout: 1, open_timeout: 1 })
        end
      end

      def inspect_head
        with_retry(1, 1) do
          head('inspect', { read_timeout: 1, open_timeout: 1 })
        end
      end

      def response_metadata_options
        with_retry(1, 1) do
          options('response-metadata', { read_timeout: 1, open_timeout: 1 })
        end
      end

      def inspect_request(verb, body)
        with_retry(1, 1) do
          headers = inspect_headers(verb)

          with_exception do
            RestClient::Request.execute(
              method: verb.to_sym,
              url: URI.join(host, 'inspect').to_s,
              payload: body,
              headers:,
              read_timeout: 1,
              open_timeout: 1
            )
          end
        end
      end

      def inspect_request_with_proxy_credentials(verb)
        with_retry(1, 1) do
          headers = {
            authorization: 'Bearer app-token',
            proxy_authorization: 'Basic proxy-secret',
            content_type: :json,
            accept: :json
          }

          with_exception do
            RestClient::Request.execute(
              method: verb.to_sym,
              url: URI.join(host, 'inspect').to_s,
              payload: 'Hello World!',
              headers:,
              read_timeout: 1,
              open_timeout: 1
            )
          end
        end
      end

      def inspect_request_with_hop_by_hop_headers
        with_retry(1, 1) do
          post(
            'inspect',
            'Hello World!',
            {
              headers: {
                connection: 'X-Connection-Scoped',
                x_connection_scoped: 'not-for-upstream',
                keep_alive: 'timeout=5',
                te: 'trailers',
                trailer: 'X-Trailer',
                transfer_encoding: 'chunked',
                upgrade: 'websocket',
                content_type: :json
              },
              read_timeout: 1,
              open_timeout: 1
            }
          )
        end
      end

      def raw_path(path)
        socket = TCPSocket.open('127.0.0.1', URI(host).port)
        socket.write("GET #{path} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
        socket.read
      ensure
        socket&.close
      end

      def not_found
        with_retry(1, 1) do
          get('notfound', { headers: { content_type: :json, accept: :json }, read_timeout: 1, open_timeout: 1 })
        end
      end

      private

      def inspect_headers(verb)
        headers = { content_type: :json, accept: :json }

        case verb.to_sym
        when :post
          Nonnative::Header.auth_basic('test:test').merge(headers)
        when :put, :delete
          Nonnative::Header.auth_bearer('token').merge(headers)
        when :patch
          Nonnative::Header.http_user_agent('test 1.0').merge(headers)
        else
          headers
        end
      end
    end
  end
end
