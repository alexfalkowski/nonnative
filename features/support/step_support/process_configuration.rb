# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module ProcessConfiguration
        PROCESS_DEFINITIONS = [
          {
            name: 'start_1',
            command: -> { 'features/support/bin/start 20_005' },
            timeout: 5,
            host: '127.0.0.1',
            port: 12_321,
            log: 'test/reports/12_321.log',
            signal: 'INT',
            environment: { 'STRING' => 'true' },
            proxy: {
              kind: 'fault_injection',
              host: '127.0.0.1',
              port: 20_005,
              log: 'test/reports/proxy_start_1.log',
              wait: 1,
              options: { delay: 10 }
            }
          },
          {
            name: 'start_2',
            command: -> { 'features/support/bin/start 12_322' },
            timeout: 5,
            port: 12_322,
            log: 'test/reports/12_322.log',
            signal: 'TERM'
          }
        ].freeze

        def configure_processes_programmatically
          configure_with_defaults do |config|
            PROCESS_DEFINITIONS.each { |definition| add_process(config, definition) }
          end
        end

        private

        def add_process(config, definition)
          config.process do |process|
            apply_process_definition(process, definition)
          end
        end

        def apply_process_definition(process, definition)
          %i[name command timeout wait host port log signal environment proxy].each do |attribute|
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
