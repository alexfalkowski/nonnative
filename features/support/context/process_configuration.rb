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
            readiness: { port: 12_427, path: '/test/readyz' }
          }
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
