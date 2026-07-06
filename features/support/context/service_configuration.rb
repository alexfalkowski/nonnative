# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ServiceConfiguration
        private

        def add_service(config, definition)
          config.service do |service|
            service.name = definition[:name]
            service.host = definition[:host]
            service.port = definition[:port]
            service.timeout = definition[:timeout] if definition[:timeout]
            service.readiness = definition[:readiness] if definition[:readiness]
            service.proxy = definition[:proxy] if definition[:proxy]
          end
        end
      end
    end
  end
end
