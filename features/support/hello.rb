# frozen_string_literal: true

module Nonnative
  module Features
    module Hello
      class << self
        def registered(app)
          app.get '/hello' do
            'Hello World!'.to_json
          end

          app.post '/hello' do
            request.body.read
          end

          app.put '/hello' do
            request.body.read
          end

          app.delete '/hello' do
            'Hello World!'.to_json
          end
        end
      end
    end
  end
end
