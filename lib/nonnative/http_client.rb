# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
    end

    protected

    def get(pathname, headers = {})
      uri = URI.join(host, pathname)
      RestClient.get(uri.to_s, headers(headers))
    rescue RestClient::Exception => e
      e.response
    end

    def post(pathname, payload, headers = {})
      uri = URI.join(host, pathname)
      RestClient.post(uri.to_s, payload.to_json, headers(headers))
    rescue RestClient::Exception => e
      e.response
    end

    private

    attr_reader :host

    def headers(headers)
      default_headers = { content_type: :json, accept: :json }
      default_headers.merge(headers)
    end
  end
end
