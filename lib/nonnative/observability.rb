# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health
      get('healthz', { content_type: :json, accept: :json })
    end

    def liveness
      get('livez', { content_type: :json, accept: :json })
    end

    def readiness
      get('readyz', { content_type: :json, accept: :json })
    end

    def metrics
      get('metrics')
    end
  end
end
