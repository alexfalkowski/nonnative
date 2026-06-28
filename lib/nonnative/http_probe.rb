# frozen_string_literal: true

module Nonnative
  # Probes a managed process HTTP readiness endpoint.
  class HTTPProbe < Nonnative::HTTPClient
    NETWORK_ERRORS = [
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      SocketError,
      RestClient::Exceptions::Timeout,
      RestClient::ServerBrokeConnection
    ].freeze

    # @param process [Nonnative::ConfigurationProcess] process configuration with readiness attributes
    def initialize(process)
      @readiness = process.readiness
      @base_url = "http://#{process.host}:#{readiness.port}"
      @timeout = Nonnative::Timeout.new(process.timeout)

      super(base_url)
    end

    # Returns whether the configured HTTP endpoint returns a 2xx response before timeout.
    #
    # @return [Boolean]
    def ready?
      Nonnative.logger.info "checking if readiness '#{endpoint}' is ready"

      timeout.perform do
        response = get(path)
        raise Nonnative::Error unless ready_response?(response)

        true
      rescue Nonnative::Error, *NETWORK_ERRORS
        sleep_interval
        retry
      end
    end

    # Returns the HTTP readiness endpoint for lifecycle diagnostics.
    #
    # @return [String]
    def endpoint
      "#{base_url}#{path}"
    end

    private

    attr_reader :base_url, :readiness, :timeout

    def path
      readiness.path.start_with?('/') ? readiness.path : "/#{readiness.path}"
    end

    def ready_response?(response)
      response.respond_to?(:code) && response.code.to_i.between?(200, 299)
    end

    def sleep_interval
      sleep 0.01
    end
  end
end
