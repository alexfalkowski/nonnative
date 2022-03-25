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
        request.body.read
      end

      put '/hello' do
        request.body.read
      end

      delete '/hello' do
        'Hello World!'.to_json
      end

      get '/health' do
        status 200
      end

      get '/liveness' do
        status 200
      end

      get '/readiness' do
        status 200
      end

      get '/metrics' do
        status 200
      end
    end
  end
end
