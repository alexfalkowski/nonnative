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
      def configure(http)
        http.register(Hello)
      end
    end
  end
end
