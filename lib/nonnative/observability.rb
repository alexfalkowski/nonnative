# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health(opts = {})
      get('healthz', opts)
    end

    def liveness(opts = {})
      get('livez', opts)
    end

    def readiness(opts = {})
      get('readyz', opts)
    end

    def metrics(opts = {})
      get('metrics', opts)
    end
  end
end
