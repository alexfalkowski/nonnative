# frozen_string_literal: true

module Nonnative
  # HTTP client for common observability endpoints exposed by the system under test.
  #
  # This client is returned by {Nonnative.observability} and builds endpoint paths from
  # {Nonnative::Configuration#name}.
  #
  # Endpoints:
  # - `/<name>/healthz`
  # - `/<name>/livez`
  # - `/<name>/readyz`
  # - `/<name>/metrics`
  #
  # Requests are performed using {Nonnative::HTTPClient}, so callers may pass RestClient options
  # such as `headers`, `open_timeout`, and `read_timeout`.
  #
  # @example
  #   Nonnative.configure do |config|
  #     config.name = 'my-service'
  #     config.url = 'http://127.0.0.1:8080'
  #   end
  #
  #   response = Nonnative.observability.health(read_timeout: 2, open_timeout: 2)
  #   response.code # => 200
  #
  # @see Nonnative.observability
  # @see Nonnative::HTTPClient
  class Observability < Nonnative::HTTPClient
    # Calls `/<name>/healthz`.
    #
    # @param opts [Hash] RestClient options (e.g. `headers`, `read_timeout`, `open_timeout`)
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def health(opts = {})
      get("#{name}/healthz", opts)
    end

    # Calls `/<name>/livez`.
    #
    # @param opts [Hash] RestClient options (e.g. `headers`, `read_timeout`, `open_timeout`)
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def liveness(opts = {})
      get("#{name}/livez", opts)
    end

    # Calls `/<name>/readyz`.
    #
    # @param opts [Hash] RestClient options (e.g. `headers`, `read_timeout`, `open_timeout`)
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def readiness(opts = {})
      get("#{name}/readyz", opts)
    end

    # Calls `/<name>/metrics`.
    #
    # @param opts [Hash] RestClient options (e.g. `headers`, `read_timeout`, `open_timeout`)
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def metrics(opts = {})
      get("#{name}/metrics", opts)
    end

    protected

    # Returns the configured system name used as the endpoint prefix.
    #
    # @return [String, nil]
    def name
      Nonnative.configuration.name
    end
  end
end
