# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
      @expections = [
        RestClient::Exceptions::Timeout,
        RestClient::ServerBrokeConnection
      ]
    end

    protected

    def with_retry(tries, wait, &)
      Retriable.retriable(tries: tries, base_interval: wait, on: expections, &)
    end

    def get(pathname, opts = {})
      with_exception do
        resource(pathname, opts).get
      end
    end

    def post(pathname, payload, opts = {})
      with_exception do
        resource(pathname, opts).post(payload)
      end
    end

    def delete(pathname, opts = {})
      with_exception do
        resource(pathname, opts).delete
      end
    end

    def put(pathname, payload, opts = {})
      with_exception do
        resource(pathname, opts).put(payload)
      end
    end

    def resource(pathname, opts)
      RestClient::Resource.new(URI.join(host, pathname).to_s, opts)
    end

    private

    attr_reader :host, :expections

    def with_exception
      yield
    rescue *expections => e
      raise e
    rescue RestClient::Exception => e
      e.response
    end
  end
end
