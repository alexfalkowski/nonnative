# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super(Service.new, service)
      end
    end

    class ComposedHTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super({ '/mounted' => MountedService.new, '/' => Service.new }, service)
      end
    end

    class EmptyHTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super({}, service)
      end
    end

    class MountedService < Nonnative::HTTPService
      get '/hello' do
        'Mounted World!'.to_json
      end
    end

    class Service < Nonnative::HTTPService
      class << self
        attr_accessor :health_body, :health_status
      end

      self.health_body = ''
      self.health_status = 200

      configure do
        set :logging, false
      end

      helpers do
        def inspect_request
          request_details.merge(request_headers)
        end

        def request_details
          {
            method: request.request_method,
            body: request.body.read,
            content_type: request.media_type,
            content_length: request.content_length
          }
        end

        def request_headers
          {
            authorization: request.env['HTTP_AUTHORIZATION'],
            proxy_authorization: request.env['HTTP_PROXY_AUTHORIZATION'],
            user_agent: request.env['HTTP_USER_AGENT']
          }.merge(hop_by_hop_request_headers)
        end

        def hop_by_hop_request_headers
          {
            connection: request.env['HTTP_CONNECTION'],
            connection_scoped: request.env['HTTP_X_CONNECTION_SCOPED'],
            keep_alive: request.env['HTTP_KEEP_ALIVE'],
            te: request.env['HTTP_TE'],
            trailer: request.env['HTTP_TRAILER'],
            transfer_encoding: request.env['HTTP_TRANSFER_ENCODING'],
            upgrade: request.env['HTTP_UPGRADE']
          }
        end

        def preserved_metadata_response
          headers(
            'Content-Type' => 'application/problem+json',
            'ETag' => '"response-v1"',
            'X-End-To-End' => 'preserved',
            'WWW-Authenticate' => 'Bearer realm="response-test"',
            'Proxy-Authenticate' => 'Basic realm="proxy"',
            'Connection' => 'X-Upstream-Only',
            'X-Upstream-Only' => 'not-forwarded'
          )
          status 201
          'upstream response body'
        end
      end

      get '/hello' do
        'Hello World!'.to_json
      end

      post '/hello' do
        request.body.read.to_json
      end

      put '/hello' do
        request.body.read.to_json
      end

      patch '/hello' do
        request.body.read.to_json
      end

      delete '/hello' do
        'Hello World!'.to_json
      end

      options '/hello' do
        status 200
      end

      get '/response-metadata' do
        preserved_metadata_response
      end

      get '/café' do
        'Café'.to_json
      end

      get '/a[b]' do
        'brackets'.to_json
      end

      options '/response-metadata' do
        preserved_metadata_response
      end

      post '/inspect' do
        inspect_request.to_json
      end

      put '/inspect' do
        inspect_request.to_json
      end

      patch '/inspect' do
        inspect_request.to_json
      end

      delete '/inspect' do
        inspect_request.to_json
      end

      head '/inspect' do
        status 200
      end

      get '/test/healthz' do
        status Nonnative::Features::Service.health_status
        Nonnative::Features::Service.health_body
      end

      get '/test/livez' do
        status 200
      end

      get '/test/readyz' do
        status 200
      end

      get '/test/metrics' do
        status 200
      end
    end
  end
end
