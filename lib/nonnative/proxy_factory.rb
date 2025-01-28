# frozen_string_literal: true

module Nonnative
  class ProxyFactory
    class << self
      def create(service)
        proxy = Nonnative.proxy(service.proxy.kind)

        proxy.new(service)
      end
    end
  end
end
