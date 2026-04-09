# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module BenchmarkConfiguration
        def configure_no_op_server
          configure_with_defaults do |config|
            add_server(config, klass: Nonnative::Features::NoOpServer, timeout: 1, port: 14_000)
          end
        end

        def configure_no_stop_server
          configure_with_defaults do |config|
            add_server(config, klass: Nonnative::Features::NoStopServer, timeout: 1, port: 14_001)
          end
        end

        def configure_start_error_server
          configure_with_defaults do |config|
            add_server(
              config,
              name: 'rollback_server',
              host: '127.0.0.1',
              klass: Nonnative::Features::TCPServer,
              timeout: 1,
              port: 14_002,
              log: 'test/reports/14_002.log'
            )
            add_server(
              config,
              name: 'fail_start_server',
              host: '127.0.0.1',
              klass: Nonnative::Features::FailStartServer,
              timeout: 1,
              port: 14_003,
              log: 'test/reports/14_003.log'
            )
          end
        end

        def configure_fast_exiting_process
          configure_with_defaults do |config|
            add_process(
              config,
              name: 'fast_exit_process',
              command: -> { "#{RbConfig.ruby} -e \"exit 0\"" },
              timeout: 1,
              wait: 1,
              host: '127.0.0.1',
              port: 14_006,
              log: 'test/reports/14_006.log',
              signal: 'INT',
              proxy: {
                kind: 'fault_injection',
                host: '127.0.0.1',
                port: 24_006,
                log: 'test/reports/proxy_14_006.log',
                wait: 0.1
              }
            )
          end
        end

        def configure_stop_error_server
          configure_with_defaults do |config|
            add_server(
              config,
              name: 'fail_stop_server',
              host: '127.0.0.1',
              klass: Nonnative::Features::FailStopServer,
              timeout: 1,
              port: 14_004,
              log: 'test/reports/14_004.log'
            )
            add_server(
              config,
              name: 'cleanup_server',
              host: '127.0.0.1',
              klass: Nonnative::Features::TCPServer,
              timeout: 1,
              port: 14_005,
              log: 'test/reports/14_005.log'
            )
          end
        end
      end
    end
  end
end
