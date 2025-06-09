# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPServer < Nonnative::HTTPServer
      def initialize(service)
        app = Sinatra.new(Application) do
          configure do
            set :logging, false
          end
        end

        super(app, service)
      end
    end

    class Application < Sinatra::Application
      configure do
        set :logging, false
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

      delete '/hello' do
        'Hello World!'.to_json
      end

      get '/test/healthz' do
        status 200
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
