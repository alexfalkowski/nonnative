# frozen_string_literal: true

module Nonnative
  class Service < Runner
    def start
      proxy.start

      Nonnative.logger.info "started service '#{service.name}'"
    end

    def stop
      proxy.stop

      Nonnative.logger.info "stopped service '#{service.name}'"
    end
  end
end
