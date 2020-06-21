# frozen_string_literal: true

module Nonnative
  class ProxyFactory
    class << self
      def create(service)
        # By default we want no proxy.
        NoProxy.new(service)
      end
    end
  end
end
