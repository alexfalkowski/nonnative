# frozen_string_literal: true

module Nonnative
  class HTTPClient
    def initialize(host)
      @host = host
    end

    protected

    def get(pathname, headers = {})
      uri = URI.join(host, pathname)
      RestClient.get(uri.to_s, headers)
    rescue RestClient::Exception => e
      e.response
    end

    def post(pathname, payload, headers = {})
      uri = URI.join(host, pathname)
      RestClient.post(uri.to_s, payload.to_json, headers)
    rescue RestClient::Exception => e
      e.response
    end

    private

    attr_reader :host
  end
end
