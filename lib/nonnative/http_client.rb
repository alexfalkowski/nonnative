# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
    end

    protected

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

    attr_reader :host

    def with_exception
      yield
    rescue RestClient::Exceptions::ReadTimeout => e
      raise e
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
