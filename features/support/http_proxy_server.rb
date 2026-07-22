# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('www.afalkowski.com', service)
      end
    end

    class LocalHTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('127.0.0.1', service, scheme: 'http', port: 4571)
      end
    end

    class UnreachableHTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('127.0.0.1', service, scheme: 'http', port: 65_534)
      end
    end

    class UnresponsiveHTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('127.0.0.1', service, scheme: 'http', port: 4571)
      end
    end

    class ShortTimeoutHTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('127.0.0.1', service, scheme: 'http', port: 4571, upstream_timeout: 0.1)
      end
    end
  end
end
