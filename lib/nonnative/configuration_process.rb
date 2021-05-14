# frozen_string_literal: true

module Nonnative
  class ConfigurationProcess < ConfigurationRunner
    attr_accessor :command, :signal, :timeout, :log, :environment
  end
end
