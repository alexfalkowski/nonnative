# frozen_string_literal: true

require 'fileutils'

module Nonnative
  module Features
    module Context
      module ServiceConfiguration
        SERVICES = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 20_006,
            proxy: {
              kind: 'fault_injection',
              host: '127.0.0.1',
              port: 30_000,
              log: 'test/reports/proxy_service_1.log',
              wait: 0.1,
              options: { delay: 0.1 }
            }
          }
        ].freeze

        NO_PROXY_SERVICES = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 30_000
          }
        ].freeze

        MISSING_UPSTREAM_SERVICES = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 20_006,
            proxy: {
              kind: 'fault_injection',
              host: '127.0.0.1',
              port: 30_001,
              log: 'test/reports/proxy_service_1.log',
              wait: 0.1,
              options: { delay: 0.1 }
            }
          }
        ].freeze

        def configure_services_programmatically
          configure_with_defaults do |config|
            SERVICES.each { |definition| add_service(config, definition) }
          end
        end

        def configure_services_without_proxies_programmatically
          configure_with_defaults do |config|
            NO_PROXY_SERVICES.each { |definition| add_service(config, definition) }
          end
        end

        def configure_services_with_missing_upstreams_programmatically
          FileUtils.rm_f(MISSING_UPSTREAM_SERVICES.first[:proxy][:log])

          configure_with_defaults do |config|
            MISSING_UPSTREAM_SERVICES.each { |definition| add_service(config, definition) }
          end
        end

        private

        def add_service(config, definition)
          config.service do |service|
            service.name = definition[:name]
            service.host = definition[:host]
            service.port = definition[:port]
            service.proxy = definition[:proxy] if definition[:proxy]
          end
        end
      end
    end
  end
end
