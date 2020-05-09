# frozen_string_literal: true

module Nonnative
  module Features
    module Metrics
      class << self
        def registered(app)
          app.get '/metrics' do
            status 200
          end
        end
      end
    end
  end
end
