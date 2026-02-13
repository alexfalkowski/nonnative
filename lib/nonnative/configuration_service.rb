# frozen_string_literal: true

module Nonnative
  # Service-specific configuration.
  #
  # A "service" is proxy-only: it does not start a Ruby thread or OS process. It exists so Nonnative can
  # start and control a proxy in front of an external dependency.
  #
  # Instances are usually created through {Nonnative::Configuration#service}.
  #
  # @see Nonnative::Configuration
  # @see Nonnative::Service
  class ConfigurationService < ConfigurationRunner
  end
end
