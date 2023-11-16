# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health(opts = {})
      opts[:headers] ||= { content_type: :json, accept: :json }

      get('healthz', opts)
    end

    def liveness(opts = {})
      opts[:headers] ||= { content_type: :json, accept: :json }

      get('livez', opts)
    end

    def readiness(opts = {})
      opts[:headers] ||= { content_type: :json, accept: :json }

      get('readyz', opts)
    end

    def metrics(opts = {})
      get('metrics', opts)
    end
  end
end
