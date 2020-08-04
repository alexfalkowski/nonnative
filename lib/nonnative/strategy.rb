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
      @env_strategy ||= ENV['NONNATIVE_STRATEGY']
    end

    def env_timeout
      @env_timeout ||= ENV['NONNATIVE_TIMEOUT']
    end
  end
end
