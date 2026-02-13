# frozen_string_literal: true

module Nonnative
  # Minimal RestClient-based HTTP client with consistent exception handling.
  #
  # This class is intended to be subclassed by higher-level clients (for example
  # {Nonnative::Observability}). It provides protected helpers for common HTTP verbs and a retry
  # wrapper.
  #
  # Error handling behavior:
  # - Timeouts and broken connections (see {#initialize}) are re-raised so callers can handle them explicitly.
  # - Other `RestClient::Exception` errors return the underlying `response` object.
  #
  # @see Nonnative::Observability
  class HTTPClient
    # @param host [String] base URL used to build request URLs (e.g. `"http://127.0.0.1:8080"`)
    def initialize(host)
      @host = host
      @exceptions = [
        RestClient::Exceptions::Timeout,
        RestClient::ServerBrokeConnection
      ]
    end

    protected

    # Executes the given block with retries for the configured network exceptions.
    #
    # @param tries [Integer] number of attempts
    # @param wait [Numeric] base interval between retries (seconds)
    # @yield the work to retry
    # @return [Object] the block result
    def with_retry(tries, wait, &)
      Retriable.retriable(tries: tries, base_interval: wait, on: exceptions, &)
    end

    # Performs a GET request.
    #
    # @param pathname [String] path relative to `host`
    # @param opts [Hash] RestClient request options (e.g. `headers`, `read_timeout`, `open_timeout`)
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def get(pathname, opts = {})
      with_exception do
        resource(pathname, opts).get
      end
    end

    # Performs a POST request.
    #
    # @param pathname [String] path relative to `host`
    # @param payload [Object] request payload
    # @param opts [Hash] RestClient request options
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def post(pathname, payload, opts = {})
      with_exception do
        resource(pathname, opts).post(payload)
      end
    end

    # Performs a DELETE request.
    #
    # @param pathname [String] path relative to `host`
    # @param opts [Hash] RestClient request options
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def delete(pathname, opts = {})
      with_exception do
        resource(pathname, opts).delete
      end
    end

    # Performs a PUT request.
    #
    # @param pathname [String] path relative to `host`
    # @param payload [Object] request payload
    # @param opts [Hash] RestClient request options
    # @return [RestClient::Response, String] response for non-2xx errors, otherwise the RestClient result
    def put(pathname, payload, opts = {})
      with_exception do
        resource(pathname, opts).put(payload)
      end
    end

    # Creates a RestClient resource for a relative path.
    #
    # @param pathname [String] path relative to `host`
    # @param opts [Hash] RestClient request options
    # @return [RestClient::Resource]
    def resource(pathname, opts)
      RestClient::Resource.new(URI.join(host, pathname).to_s, opts)
    end

    private

    attr_reader :host, :exceptions

    def with_exception
      yield
    rescue *exceptions => e
      raise e
    rescue RestClient::Exception => e
      e.response
    end
  end
end
