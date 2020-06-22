# frozen_string_literal: true

module Nonnative
  class ProxyFactory
    class << self
      def create(service)
        case service.proxy
        when 'chaos'
          ChaosProxy.new(service)
        else
          # By default we want no proxy.
          NoProxy.new(service)
        end
      end
    end
  end
end
