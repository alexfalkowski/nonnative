# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('www.afalkowski.com', service)
      end
    end
  end
end
