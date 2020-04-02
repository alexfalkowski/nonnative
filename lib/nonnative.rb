# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'thwait'
require 'yaml'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_process'
require 'nonnative/system'
require 'nonnative/pool'
require 'nonnative/logger'

module Nonnative
  class << self
    def logger
      @logger ||= Nonnative::Logger.create
    end

    def load_configuration(path)
      @configuration ||= Nonnative::Configuration.load_file(path) # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration if block_given?

      require "nonnative/#{configuration.strategy}"
    end

    def start
      @process_pool ||= Nonnative::Pool.new(configuration)

      @process_pool.start do |pid, result|
        logger.error('Process has started though did respond in time', pid: pid) unless result
      end
    end

    def stop
      @process_pool.stop do |pid, result|
        logger.error('Process has stopped though did respond in time', pid: pid) unless result
      end
    end

    def clear
      @logger = nil
      @configuration = nil
      @process_pool = nil
    end
  end
end
