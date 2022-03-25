# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health
      get('health', { content_type: :json, accept: :json })
    end

    def liveness
      get('liveness', { content_type: :json, accept: :json })
    end

    def readiness
      get('readiness', { content_type: :json, accept: :json })
    end

    def metrics
      get('metrics')
    end
  end
end
