# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPServer < Nonnative::HTTPServer
      def app
        Application.new
      end
    end

    class Application < Sinatra::Application
      configure do
        set :server_settings, log_requests: true
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

      get '/healthz' do
        status 200
      end

      get '/livez' do
        status 200
      end

      get '/readyz' do
        status 200
      end

      get '/metrics' do
        status 200
      end
    end
  end
end
