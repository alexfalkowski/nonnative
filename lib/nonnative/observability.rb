# frozen_string_literal: true

module Nonnative
  class Observability < Nonnative::HTTPClient
    def health
      get('health')
    end
  end
end
