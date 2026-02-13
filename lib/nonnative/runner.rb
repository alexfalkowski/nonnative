# frozen_string_literal: true

module Nonnative
  # Base runtime wrapper for a configured runnable unit.
  #
  # A runner wraps a configuration object (a subclass of {Nonnative::ConfigurationRunner}) and
  # exposes lifecycle behavior via specialized subclasses:
  #
  # - {Nonnative::Process} for OS-level child processes
  # - {Nonnative::Server} for in-process Ruby servers (threads)
  # - {Nonnative::Service} for proxy-only external dependencies
  #
  # Each runner has an associated proxy instance created via {Nonnative::ProxyFactory}.
  #
  # @see Nonnative::Process
  # @see Nonnative::Server
  # @see Nonnative::Service
  class Runner
    # Returns the proxy instance for this runner.
    #
    # @return [Nonnative::Proxy]
    attr_reader :proxy

    # @param service [Nonnative::ConfigurationRunner] runner configuration
    def initialize(service)
      @service = service
      @proxy = Nonnative::ProxyFactory.create(service)
    end

    # Returns the configured runner name.
    #
    # @return [String, nil]
    def name
      service.name
    end

    protected

    # Returns the underlying configuration object.
    #
    # @return [Nonnative::ConfigurationRunner]
    attr_reader :service

    # Sleeps for the configured `wait` interval after start-related work.
    #
    # @return [void]
    def wait_start
      sleep service.wait
    end

    # Sleeps for the configured `wait` interval after stop-related work.
    #
    # @return [void]
    def wait_stop
      sleep service.wait
    end
  end
end
