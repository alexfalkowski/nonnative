# frozen_string_literal: true

module Nonnative
  # Probes a managed process gRPC health endpoint.
  class GRPCProbe
    # @param process [Nonnative::ConfigurationProcess] process configuration
    # @param readiness [Nonnative::ConfigurationReadiness] gRPC readiness attributes
    def initialize(process, readiness)
      @health = Nonnative::GRPCHealth.new(
        host: process.host,
        port: readiness.port,
        service: readiness.service,
        timeout: process.timeout
      )
      @timeout = Nonnative::Timeout.new(process.timeout)
    end

    # Returns whether the configured gRPC health endpoint reports SERVING before timeout.
    #
    # @return [Boolean]
    def ready?
      Nonnative.logger.info "checking if readiness '#{endpoint}' is ready"

      timeout.perform do
        raise Nonnative::Error unless health.serving?

        true
      rescue Nonnative::Error
        sleep_interval
        retry
      end
    end

    # Returns the gRPC health endpoint for lifecycle diagnostics.
    #
    # @return [String]
    def endpoint
      health.endpoint
    end

    private

    attr_reader :health, :timeout

    def sleep_interval
      sleep 0.01
    end
  end
end
