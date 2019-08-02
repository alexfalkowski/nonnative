# frozen_string_literal: true

require 'semantic_logger'

SemanticLogger.default_level = :info
SemanticLogger.add_appender(io: STDOUT, formatter: :color)

module Nonnative
  class Logger
    class << self
      def create
        SemanticLogger['nonnative']
      end
    end
  end
end
