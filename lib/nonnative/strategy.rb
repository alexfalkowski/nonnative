# frozen_string_literal: true

module Nonnative
  class Strategy
    def initialize(strategy = 'before', timeout = 5)
      @strategy = strategy
      @timeout = timeout
    end

    def timeout
      (env_timeout || @timeout).to_i
    end

    def to_s
      (env_strategy || @strategy).to_s
    end

    private

    def env_strategy
      @env_strategy ||= ENV.fetch('NONNATIVE_STRATEGY', nil)
    end

    def env_timeout
      @env_timeout ||= ENV.fetch('NONNATIVE_TIMEOUT', nil)
    end
  end
end
