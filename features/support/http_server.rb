# frozen_string_literal: true

module Nonnative
  module Features
    module Hello
      class << self
        def registered(app)
          app.get '/hello' do
            'Hello World!'
          end
        end
      end
    end

    class HTTPServer < Nonnative::HTTPServer
      configure do |app|
        app.register(Hello)
      end
    end
  end
end
