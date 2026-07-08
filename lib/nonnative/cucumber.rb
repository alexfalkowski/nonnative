# frozen_string_literal: true

require 'cucumber'

module Nonnative
  # Lazily installs the Cucumber integration once the Cucumber Ruby DSL is ready.
  #
  # Requiring `nonnative` outside a running Cucumber environment should not fail, but when Cucumber
  # does finish booting its support-code registry this installer still needs to register the hooks
  # and step definitions defined here.
  #
  # Supported hooks:
  # - `@startup`: start before scenario, stop after scenario
  # - `@manual`: stop after scenario; use `When I start the system` to start manually
  # - `@clear`: clear memoized Nonnative state before scenario
  # - `@reset`: reset proxies after scenario
  #
  # Installed step definitions:
  # - `Given I set the proxy for service {string} to {string}`
  # - `Then I should reset the proxy for service {string}`
  # - `When I start the system`
  # - `When I attempt to start the system`
  # - `When I attempt to stop the system`
  # - `Then I should see {string} as unhealthy`
  # - `Then I should see {string} as healthy`
  # - `Then the process {string} should consume less than {string} of memory`
  # - `Then starting the system should raise an error`
  # - `Then stopping the system should raise an error`
  # - `Then I should see a log entry of {string} for process {string}`
  # - `Then I should see a log entry of {string} in the file {string}`
  module Cucumber
    module LanguageHook
      def rb_language=(value)
        super.tap { ::Nonnative::Cucumber.install! }
      end
    end

    module WorldHooks
      def install_world
        World(::RSpec::Benchmark::Matchers)
        World(::RSpec::Matchers)
        World(::RSpec::Wait)
      end

      def install_hooks
        # Register @clear before startup hooks so combined tags reset stale state before creating a pool.
        Before('@clear') { Nonnative.clear }
        Before('@startup') { Nonnative.start }
        After('@startup') { Nonnative.stop }
        After('@manual') { Nonnative.stop }
        After('@reset') { Nonnative.reset }
      end
    end

    module ProxySteps
      PROXY_OPERATIONS = {
        'close_all' => :close_all,
        'reset_peer' => :reset_peer,
        'delay' => :delay,
        'timeout' => :timeout,
        'invalid_data' => :invalid_data,
        'reset' => :reset
      }.freeze

      def install_proxy_steps
        install_proxy_mutation_steps
        install_proxy_reset_steps
      end

      def install_proxy_mutation_steps
        Given('I set the proxy for service {string} to {string}') do |name, operation|
          service = Nonnative.pool.service_by_name(name)
          Nonnative::Cucumber::Registration.apply_proxy_operation(service.proxy, operation)
        end
      end

      def install_proxy_reset_steps
        Then('I should reset the proxy for service {string}') do |name|
          service = Nonnative.pool.service_by_name(name)
          service.proxy.reset
        end
      end

      def apply_proxy_operation(proxy, operation)
        method = PROXY_OPERATIONS.fetch(operation) do
          raise ArgumentError, "Unsupported proxy operation '#{operation}'"
        end

        proxy.public_send(method)
      end
    end

    module LifecycleSteps
      SERVICE_UNAVAILABLE = 'service unavailable'

      def install_state_steps
        install_start_step
        install_attempt_start_step
        install_attempt_stop_step
        install_unhealthy_step
        install_healthy_step
      end

      def install_start_step
        When('I start the system') do
          Nonnative.start
        end
      end

      def install_attempt_start_step
        When('I attempt to start the system') do
          @start_error = nil
          Nonnative.start
        rescue StandardError => e
          @start_error = e
        end
      end

      def install_attempt_stop_step
        When('I attempt to stop the system') do
          @stop_error = nil
          Nonnative.stop
        rescue StandardError => e
          @stop_error = e
        end
      end

      def install_unhealthy_step
        opts = observability_options

        Then('I should see {string} as unhealthy') do |service|
          service = service.downcase
          wait_for { Nonnative.observability.health(opts).code }.to eq(503)
          wait_for { Nonnative.observability.health(opts).body }.to satisfy do |body|
            body = body.to_s.strip.downcase

            body.include?(SERVICE_UNAVAILABLE) || body.include?(service)
          end
        end
      end

      def install_healthy_step
        opts = observability_options

        Then('I should see {string} as healthy') do |service|
          service = service.downcase
          wait_for { Nonnative.observability.health(opts).code }.to eq(200)
          wait_for { Nonnative.observability.health(opts).body }.to satisfy do |body|
            body = body.to_s.strip.downcase

            !body.include?(SERVICE_UNAVAILABLE) && !body.include?(service)
          end
        end
      end

      def observability_options
        {
          headers: { content_type: :json, accept: :json },
          read_timeout: 10,
          open_timeout: 10
        }
      end
    end

    module Assertions
      def install_assertion_steps
        install_memory_assertion_step
        install_error_assertion_steps
        install_log_assertion_steps
      end

      def install_memory_assertion_step
        Then('the process {string} should consume less than {string} of memory') do |name, mem|
          process = Nonnative.pool.process_by_name(name)
          _, size, type = mem.split(/(\d+)/)
          actual = process.memory.send(type)
          size = size.to_i

          expect(actual).to be < size
        end
      end

      def install_error_assertion_steps
        Then('starting the system should raise an error') do
          expect(@start_error).to be_a(Nonnative::StartError)
        end

        Then('stopping the system should raise an error') do
          expect(@stop_error).to be_a(Nonnative::StopError)
        end
      end

      def install_log_assertion_steps
        Then('I should see a log entry of {string} for process {string}') do |message, process|
          process = Nonnative.configuration.process_by_name(process)
          expect(Nonnative.log_lines(process.log, ->(l) { l.include?(message) }).first).to include(message)
        end

        Then('I should see a log entry of {string} in the file {string}') do |message, path|
          expect(Nonnative.log_lines(path, ->(l) { l.include?(message) }).first).to include(message)
        end
      end
    end

    module Registration
      extend ::Cucumber::Glue::Dsl
      extend WorldHooks
      extend ProxySteps
      extend LifecycleSteps
      extend Assertions

      class << self
        def install!
          install_world
          install_hooks
          install_proxy_steps
          install_state_steps
          install_assertion_steps
        end
      end
    end

    class << self
      def bootstrap!
        return if @bootstrapped

        dsl_singleton = ::Cucumber::Glue::Dsl.singleton_class
        dsl_singleton.prepend(LanguageHook) unless dsl_singleton.ancestors.include?(LanguageHook)

        @bootstrapped = true
        install!
      end

      def install!
        return if @installed
        return unless ready?

        Registration.install!
        @installed = true
      end

      private

      def ready?
        !::Cucumber::Glue::Dsl.instance_variable_get(:@rb_language).nil?
      end
    end
  end
end

Nonnative::Cucumber.bootstrap!
