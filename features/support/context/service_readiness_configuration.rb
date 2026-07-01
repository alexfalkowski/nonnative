# frozen_string_literal: true

require 'fileutils'
require 'rbconfig'

module Nonnative
  module Features
    module Context
      module ServiceReadinessConfiguration
        SERVICE_TCP_READINESS = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 20_006,
            readiness: [{ kind: 'tcp', host: '127.0.0.1', port: 30_000 }],
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

        MISSING_TCP_READINESS = [
          {
            name: 'service_1',
            host: '127.0.0.1',
            port: 20_006,
            timeout: 0.1,
            readiness: [{ kind: 'tcp', host: '127.0.0.1', port: 30_001 }],
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

        def configure_services_with_tcp_readiness_programmatically
          configure_with_defaults do |config|
            SERVICE_TCP_READINESS.each { |definition| add_service(config, definition) }
          end
        end

        def configure_services_with_missing_tcp_readiness_programmatically
          configure_with_defaults do |config|
            MISSING_TCP_READINESS.each { |definition| add_service(config, definition) }
          end
        end

        def configure_process_with_missing_service_tcp_readiness_programmatically
          @service_readiness_process_output = 'test/reports/service_readiness_process_output'
          FileUtils.rm_f(@service_readiness_process_output)

          configure_with_defaults do |config|
            MISSING_TCP_READINESS.each { |definition| add_service(config, definition) }
            add_process(config, service_readiness_process)
          end
        end

        private

        def service_readiness_process
          {
            name: 'service_readiness_process',
            command: -> { [RbConfig.ruby, 'features/support/bin/start', '12418', @service_readiness_process_output] },
            timeout: 2,
            wait: 0.1,
            host: '127.0.0.1',
            ports: [12_418],
            log: 'test/reports/12_418.log',
            signal: 'INT'
          }
        end
      end
    end
  end
end
