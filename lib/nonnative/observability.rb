# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health(opts = {})
      get("#{name}/healthz", opts)
    end

    def liveness(opts = {})
      get("#{name}/livez", opts)
    end

    def readiness(opts = {})
      get("#{name}/readyz", opts)
    end

    def metrics(opts = {})
      get("#{name}/metrics", opts)
    end

    protected

    def name
      Nonnative.configuration.name
    end
  end
end
