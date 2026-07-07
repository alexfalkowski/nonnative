# frozen_string_literal: true

require_relative 'context/scenario_context'
require_relative 'context/configuration_files'
require_relative 'context/process_configuration'
require_relative 'context/server_configuration'
require_relative 'context/service_configuration'
require_relative 'context/service_connections'
require_relative 'context/endpoint_clients'
require_relative 'context/lifecycle_support'
require_relative 'context/network_checks'
require_relative 'context/token_verification'

module Nonnative
  module Features
    module Context
      DEFAULT_LOG = 'test/reports/nonnative.log'
      DEFAULT_NAME = 'test'
      DEFAULT_URL = 'http://localhost:4567'
      DEFAULT_VERSION = '1.0'

      include ScenarioContext
      include ConfigurationFiles
      include ProcessConfiguration
      include ServerConfiguration
      include ServiceConfiguration
      include ServiceConnections
      include EndpointClients
      include LifecycleSupport
      include NetworkChecks
      include TokenVerification
    end
  end
end

World(Nonnative::Features::Context)
