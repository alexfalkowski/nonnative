# frozen_string_literal: true

module Nonnative
  module Features
    module Health
      class << self
        def registered(app)
          app.get '/health' do
            status 200
          end
        end
      end
    end
  end
end
