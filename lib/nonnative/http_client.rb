# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
    end

    protected

    def get(pathname, headers = {})
      with_exception do
        uri = URI.join(host, pathname)
        RestClient.get(uri.to_s, headers)
      end
    end

    def post(pathname, payload, headers = {})
      with_exception do
        uri = URI.join(host, pathname)
        RestClient.post(uri.to_s, payload.to_json, headers)
      end
    end

    private

    attr_reader :host

    def with_exception
      yield
    rescue RestClient::Exception => e
      e.response
    end
  end
end
