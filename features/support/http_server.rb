# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPServer < Nonnative::HTTPServer
      def app
        Application.new
      end
    end

    class Application < Sinatra::Base
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

      get '/metrics' do
        status 200
      end
    end
  end
end
