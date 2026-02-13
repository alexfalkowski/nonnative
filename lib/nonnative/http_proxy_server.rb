# frozen_string_literal: true

# Sinatra-based HTTP forward proxy server used as an in-process Nonnative server.
#
# The proxy receives inbound HTTP requests and forwards them to an upstream host over HTTPS, returning
# the upstream response status and body.
#
# This file defines two classes:
#
# - {Nonnative::HTTPProxy}: a Sinatra application that implements the proxying behavior.
# - {Nonnative::HTTPProxyServer}: a {Nonnative::HTTPServer} wrapper that runs the proxy app under Puma.
#
# Notes:
# - This code is adapted from https://gist.github.com/RaVbaker/d9ead3c92b915f997dab25c7f0c0ab65
# - Only a subset of request headers are forwarded; certain headers are removed to avoid conflicts.
#
# @see Nonnative::HTTPServer
# @see Nonnative::Server
module Nonnative
  # Sinatra application implementing a simple forward proxy.
  #
  # The upstream host is configured via Sinatra settings (see {Nonnative::HTTPProxyServer}).
  #
  # Supported HTTP verbs: GET, POST, PUT, PATCH, DELETE.
  class HTTPProxy < Sinatra::Application
    # Extracts request headers from the Rack environment and normalizes them to standard HTTP names.
    #
    # Certain hop-by-hop or proxy-specific headers are removed.
    #
    # @param request [Sinatra::Request] the incoming request
    # @return [Hash{String=>String}] headers to forward to the upstream
    def retrieve_headers(request)
      headers = request.env.map do |header, value|
        [header[5..].split('_').map(&:capitalize).join('-'), value] if header.start_with?('HTTP_')
      end
      headers = headers.compact.to_h

      headers.except('Host', 'Accept-Encoding', 'Version')
    end

    # Builds the upstream URL for the given request.
    #
    # @param request [Sinatra::Request] the incoming request
    # @param settings [Sinatra::Base] Sinatra settings, expected to include `host`
    # @return [String] HTTPS URL for the upstream request
    def build_url(request, settings)
      URI::HTTPS.build(host: settings.host, path: request.path_info, query: request.query_string).to_s
    end

    # Executes the upstream request and returns the response.
    #
    # @param verb [String] HTTP verb name (e.g. `"get"`)
    # @param uri [String] upstream URI
    # @param opts [Hash] RestClient options (e.g. headers)
    # @return [RestClient::Response] response for error statuses, otherwise RestClient return value
    def api_response(verb, uri, opts)
      client = RestClient::Resource.new(uri, opts)

      client.send(verb)
    rescue RestClient::Exception => e
      e.response
    end

    %w[get post put patch delete].each do |verb|
      send(verb, /.*/) do
        uri = build_url(request, settings)
        opts = { headers: retrieve_headers(request) }
        res = api_response(verb, uri, opts)

        status res.code
        res.body
      end
    end
  end

  # Runs {Nonnative::HTTPProxy} as a Puma-based in-process server under Nonnative.
  #
  # @example
  #   Nonnative.configure do |config|
  #     config.server do |s|
  #       s.name = 'github-proxy'
  #       s.klass = Nonnative::Features::HTTPProxyServer
  #       s.timeout = 2
  #       s.host = '127.0.0.1'
  #       s.port = 4567
  #       s.log = 'proxy.log'
  #     end
  #   end
  #
  #   # In your server subclass:
  #   # class HTTPProxyServer < Nonnative::HTTPProxyServer
  #   #   def initialize(service)
  #   #     super('api.github.com', service)
  #   #   end
  #   # end
  #
  # @see Nonnative::HTTPServer
  class HTTPProxyServer < Nonnative::HTTPServer
    # @param host [String] upstream host to proxy to (HTTPS)
    # @param service [Nonnative::ConfigurationServer] server configuration
    def initialize(host, service)
      app = Sinatra.new(Nonnative::HTTPProxy) do
        configure do
          set :host, host
        end
      end

      super(app, service)
    end
  end
end
