# frozen_string_literal: true

module Nonnative
  class ConfigurationServer < ConfigurationRunner
    attr_accessor :klass, :timeout, :log
  end
end
