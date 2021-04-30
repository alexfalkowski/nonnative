# frozen_string_literal: true

module Nonnative
  class Service < Runner
    def start
      proxy.start
    end

    def stop
      proxy.stop
    end
  end
end
