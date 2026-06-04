# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module LifecycleSupport
        def build_pool(services: [], servers: [], processes: [])
          Nonnative::Features::SeededPool.new(Nonnative::Configuration.new, services:, servers:, processes:)
        end

        def add_lingering_process(config, name, port)
          config.process do |process|
            process.name = name
            process.command = -> { ['features/support/bin/start', port.to_s, 'linger'] }
            process.timeout = 2
            process.wait = 0.1
            process.host = '127.0.0.1'
            process.port = port
            process.log = "test/reports/#{port}.log"
            process.signal = 'INT'
          end
        end

        def add_fast_exit_process(config, name, port)
          config.process do |process|
            process.name = name
            process.command = -> { [RbConfig.ruby, '-e', 'exit 0'] }
            process.timeout = 1
            process.wait = 0.1
            process.host = '127.0.0.1'
            process.port = port
            process.log = "test/reports/#{port}.log"
            process.signal = 'INT'
          end
        end

        def cleanup_lingering_processes
          @lingering_processes&.each { |name| cleanup_lingering_process(name) }
        end

        def cleanup_lingering_process(name)
          pid = Nonnative.pool&.process_by_name(name)&.instance_variable_get(:@pid)
          return unless pid

          ::Process.kill('KILL', pid)
          ::Process.wait(pid)
        rescue Nonnative::NotFoundError, Errno::ESRCH, Errno::ECHILD
          nil
        end

        def build_ordered_pool(events)
          build_pool(
            services: [Nonnative::Features::RecordingService.new(name: 'service_1', events:)],
            servers: [[
              Nonnative::Features::RecordingRunner.new(name: 'server_1', events:),
              Nonnative::Features::PassingPort.new
            ]],
            processes: [[
              Nonnative::Features::RecordingRunner.new(name: 'process_1', events:),
              Nonnative::Features::PassingPort.new
            ]]
          )
        end

        def configure_for_clear(log:, url:)
          Nonnative.configure do |config|
            config.name = 'test'
            config.url = url
            config.log = log
          end
        end

        def observability_host(client)
          client.send(:host)
        end

        def run_subprocess(script)
          @subprocess_stdout, @subprocess_stderr, @subprocess_status = Open3.capture3(
            RbConfig.ruby,
            '-Ilib',
            '-e',
            script,
            chdir: Dir.pwd
          )
        end
      end
    end
  end
end
