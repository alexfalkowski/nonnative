# frozen_string_literal: true

module Nonnative
  class ProxyFactory
    class << self
      def create(service)
        proxy = case service.proxy.type
                when 'fault_injection'
                  FaultInjectionProxy
                else
                  NoProxy
                end

        proxy.new(service)
      end
    end
  end
end
