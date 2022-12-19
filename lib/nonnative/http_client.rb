# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
    end

    protected

    def get(pathname, headers = {}, timeout = 60)
      with_exception do
        uri = URI.join(host, pathname)
        RestClient::Request.execute(method: :get, url: uri.to_s, headers:, timeout:)
      end
    end

    def post(pathname, payload, headers = {}, timeout = 60)
      with_exception do
        uri = URI.join(host, pathname)
        RestClient::Request.execute(method: :post, url: uri.to_s, payload: payload.to_json, headers:, timeout:)
      end
    end

    def delete(pathname, headers = {}, timeout = 60)
      with_exception do
        uri = URI.join(host, pathname)
        RestClient::Request.execute(method: :delete, url: uri.to_s, headers:, timeout:)
      end
    end

    def put(pathname, payload, headers = {}, timeout = 60)
      with_exception do
        uri = URI.join(host, pathname)
        RestClient::Request.execute(method: :put, url: uri.to_s, payload: payload.to_json, headers:, timeout:)
      end
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
