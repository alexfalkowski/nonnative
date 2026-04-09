# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module ServiceConfiguration
        SERVICE_DEFINITIONS = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 20_006,
            proxy: {
              kind: 'fault_injection',
              host: '127.0.0.1',
              port: 30_000,
              log: 'test/reports/proxy_service_1.log',
              wait: 1,
              options: { delay: 7 }
            }
          }
        ].freeze

        def configure_services_programmatically
          configure_with_defaults do |config|
            SERVICE_DEFINITIONS.each { |definition| add_service(config, definition) }
          end
        end

        private

        def add_service(config, definition)
          config.service do |service|
            service.name = definition[:name]
            service.host = definition[:host]
            service.port = definition[:port]
            service.proxy = definition[:proxy]
          end
        end
      end
    end
  end
end
