# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ProcessConfiguration
        PROCESSES = [
          {
            name: 'start_1',
            command: -> { 'features/support/bin/start 12_321' },
            timeout: 5,
            host: '127.0.0.1',
            ports: [12_321],
            log: 'test/reports/12_321.log',
            signal: 'INT',
            environment: { 'STRING' => 'true' }
          },
          {
            name: 'start_2',
            command: -> { 'features/support/bin/start 12_322,12_325' },
            timeout: 5,
            ports: [12_322, 12_325],
            log: 'test/reports/12_322.log',
            signal: 'TERM'
          }
        ].freeze

        def configure_processes_programmatically
          configure_with_defaults do |config|
            PROCESSES.each { |definition| add_process(config, definition) }
          end
        end

        def configure_http_readiness_process(status:)
          configure_with_defaults do |config|
            add_process(config, http_readiness_process(status))
          end
        end

        def configure_grpc_readiness_process(status:, delay: 0)
          configure_with_defaults do |config|
            add_process(config, grpc_readiness_process(status, delay))
          end
        end

        private

        def http_readiness_process(status)
          {
            name: 'http_ready_process',
            command: -> { [RbConfig.ruby, 'features/support/bin/http_readiness', '12426', '12427', status.to_s] },
            timeout: 2,
            wait: 0.1,
            host: '127.0.0.1',
            ports: [12_426],
            log: 'test/reports/12_426.log',
            signal: 'INT',
            readiness: [{ kind: 'http', port: 12_427, path: '/test/readyz' }]
          }
        end

        def grpc_readiness_process(status, delay)
          {
            name: 'grpc_ready_process',
            command: -> { grpc_readiness_command(status, delay) },
            timeout: 2,
            wait: 0.1,
            host: '127.0.0.1',
            ports: [12_428, 12_429],
            log: 'test/reports/12_428.log',
            signal: 'INT',
            readiness: [{ kind: 'grpc', port: 12_429, service: 'nonnative.v1.GreeterService' }]
          }
        end

        def grpc_readiness_command(status, delay)
          [
            RbConfig.ruby,
            '-rbundler/setup',
            'features/support/bin/grpc_readiness',
            '12428',
            '12429',
            'nonnative.v1.GreeterService',
            status.to_s,
            delay.to_s
          ]
        end

        def add_process(config, definition)
          config.process do |process|
            apply_process_definition(process, definition)
          end
        end

        def apply_process_definition(process, definition)
          %i[name command timeout wait host ports log signal environment readiness].each do |attribute|
            assign_process_attribute(process, definition, attribute)
          end
        end

        def assign_process_attribute(process, definition, attribute)
          value = definition[attribute]
          return if value.nil?

          process.public_send("#{attribute}=", value)
        end
      end
    end
  end
end
