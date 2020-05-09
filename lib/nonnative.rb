# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'thwait'
require 'yaml'

require 'grpc'
require 'sinatra'
require 'rest-client'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_process'
require 'nonnative/configuration_server'
require 'nonnative/command'
require 'nonnative/pool'
require 'nonnative/server'
require 'nonnative/logger'
require 'nonnative/http_client'
require 'nonnative/http_server'
require 'nonnative/grpc_server'
require 'nonnative/grpc_server'
require 'nonnative/observability'

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
      @pool ||= Nonnative::Pool.new(configuration)

      @pool.start do |name, id, result|
        logger.error('Started though did respond in time', id: id, name: name) unless result
      end
    end

    def stop
      return if @pool.nil?

      @pool.stop do |name, id, result|
        logger.error('Stopped though did respond in time', id: id, name: name) unless result
      end
    end

    def clear
      @logger = nil
      @configuration = nil
      @process_pool = nil
      @pool = nil
    end
  end
end
