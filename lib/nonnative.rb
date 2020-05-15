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
require 'nonnative/start_error'
require 'nonnative/stop_error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_process'
require 'nonnative/configuration_server'
require 'nonnative/service'
require 'nonnative/command'
require 'nonnative/pool'
require 'nonnative/server'
require 'nonnative/http_client'
require 'nonnative/http_server'
require 'nonnative/grpc_server'
require 'nonnative/grpc_server'
require 'nonnative/observability'

module Nonnative
  class << self
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
        raise Nonnative::StartError, "Started #{name} with id #{id}, though did respond in time" unless result
      end
    end

    def stop
      return if @pool.nil?

      @pool.stop do |name, id, result|
        raise Nonnative::StopError, "Stopped #{name} with id #{id}, though did respond in time" unless result
      end
    end

    def clear
      @configuration = nil
      @pool = nil
    end
  end
end
