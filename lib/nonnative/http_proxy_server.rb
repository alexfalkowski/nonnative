# frozen_string_literal: true

# Sinatra-based HTTP forward proxy server used as an in-process Nonnative server.
#
# The proxy receives inbound HTTP requests and forwards them to an upstream host, defaulting to HTTPS
# on the scheme's default port but configurable to HTTP and/or a non-default port. It returns the
# upstream response status, body, and safe end-to-end response headers. Hop-by-hop,
# connection-nominated, proxy-authentication, framing, and deferred response headers are not forwarded.
#
# This file defines two classes:
#
# - {Nonnative::HTTPProxy}: an HTTP service that implements the proxying behavior.
# - {Nonnative::HTTPProxyServer}: a {Nonnative::HTTPServer} wrapper that runs the proxy app under Puma.
#
# Notes:
# - This code is adapted from https://gist.github.com/RaVbaker/d9ead3c92b915f997dab25c7f0c0ab65
# - Only a subset of request headers are forwarded; certain headers are removed to avoid conflicts.
#
# @see Nonnative::HTTPServer
# @see Nonnative::Server
module Nonnative
  # HTTP service implementing a simple forward proxy.
  #
  # The upstream host is configured via service settings (see {Nonnative::HTTPProxyServer}).
  #
  # Supported HTTP verbs: GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS.
  class HTTPProxy < Nonnative::HTTPService
    NON_FORWARDABLE_RESPONSE_HEADERS = %w[
      connection
      content-encoding
      content-length
      keep-alive
      location
      proxy-authenticate
      proxy-authorization
      proxy-authentication-info
      proxy-connection
      set-cookie
      status
      te
      trailer
      transfer-encoding
      upgrade
    ].freeze

    NON_FORWARDABLE_REQUEST_HEADERS = %w[
      Host
      Accept-Encoding
      Version
      Proxy-Authenticate
      Proxy-Authorization
    ].freeze

    # Extracts request headers from the Rack environment and normalizes them to standard HTTP names.
    #
    # Certain hop-by-hop or proxy-specific headers are removed.
    #
    # @param request [Sinatra::Request] the incoming request
    # @return [Hash{String=>String}] headers to forward to the upstream
    def forward_request_headers(request)
      headers = request.env.each_with_object({}) do |(header, value), result|
        next unless forward_request_header?(header)

        result[normalized_request_header_name(header)] = value
      end

      headers.except(*NON_FORWARDABLE_REQUEST_HEADERS)
    end

    # Builds the upstream URL for the given request.
    #
    # @param request [Sinatra::Request] the incoming request
    # @param settings [Sinatra::Base] Sinatra settings, expected to include `host`, `scheme`, and `port`
    # @return [String] upstream URL
    def build_url(request, settings)
      uri_class = settings.scheme == 'http' ? URI::HTTP : URI::HTTPS
      query = request.query_string

      uri_class.build(host: settings.host, port: settings.port, path: request.path_info, query: query.empty? ? nil : query).to_s
    end

    # Executes the upstream request and returns the response.
    #
    # @param method [Symbol] HTTP verb name (e.g. `:get`)
    # @param url [String] upstream URL
    # @param headers [Hash] request headers
    # @param payload [String, nil] request payload
    # @return [RestClient::Response] response for error statuses, otherwise RestClient return value
    def api_response(method:, url:, headers:, payload: nil)
      options = { method:, url:, headers: }
      options[:payload] = payload unless payload.nil?

      RestClient::Request.execute(options)
    rescue RestClient::Exception => e
      e.response
    end

    # Extracts the request payload for verbs that can carry a body.
    #
    # @param request [Sinatra::Request] the incoming request
    # @param verb [String] HTTP verb name (e.g. `"post"`)
    # @return [String, nil] request payload for body-carrying verbs
    def retrieve_payload(request, verb)
      return unless %w[post put patch delete].include?(verb)

      payload = request.body.read
      payload unless payload.empty?
    end

    private

    def forward_response_headers(response)
      raw_headers = response.raw_headers
      connection_headers = response_connection_headers(raw_headers)

      raw_headers.each_with_object({}) do |(header, value), result|
        normalized_header = normalized_response_header_name(header)
        next unless forward_response_header?(normalized_header, connection_headers)

        result[normalized_header] = Array(value).join(', ')
      end
    end

    def response_connection_headers(raw_headers)
      connection_headers = raw_headers.each_with_object([]) do |(header, values), result|
        next unless normalized_response_header_name(header) == 'connection'

        Array(values).each { |value| result.concat(value.to_s.split(',')) }
      end

      connection_headers.map { |header| normalized_response_header_name(header) }
    end

    def forward_response_header?(header, connection_headers)
      !NON_FORWARDABLE_RESPONSE_HEADERS.include?(header) &&
        !connection_headers.include?(header) &&
        !header.start_with?('rack.')
    end

    def normalized_response_header_name(header)
      header.to_s.strip.downcase
    end

    def forward_request_header?(header)
      header.start_with?('HTTP_') || %w[CONTENT_TYPE CONTENT_LENGTH].include?(header)
    end

    def normalized_request_header_name(header)
      header.delete_prefix('HTTP_').split('_').map(&:capitalize).join('-')
    end

    # Registered before `get` so it takes precedence over Sinatra's GET-generated HEAD route,
    # which would otherwise forward HEAD requests upstream as GET.
    head(/.*/) do
      res = api_response(method: :head, url: build_url(request, settings), headers: forward_request_headers(request))

      headers(forward_response_headers(res))
      status res.code
    end

    %w[get post put patch delete options].each do |verb|
      send(verb, /.*/) do
        res = api_response(
          method: verb.to_sym,
          url: build_url(request, settings),
          headers: forward_request_headers(request),
          payload: retrieve_payload(request, verb)
        )

        headers(forward_response_headers(res))
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
  #       s.ports = [4567]
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
    # @param host [String] upstream host to proxy to
    # @param service [Nonnative::ConfigurationServer] server configuration
    # @param scheme [String] upstream scheme, `"http"` or `"https"`
    # @param port [Integer, nil] upstream port; `nil` uses the scheme's default port
    def initialize(host, service, scheme: 'https', port: nil)
      http_service = Class.new(Nonnative::HTTPProxy) do
        set :host, host
        set :scheme, scheme
        set :port, port
      end

      super(http_service.new, service)
    end
  end
end
