# frozen_string_literal: true

module Nonnative
  # Safely loads a YAML configuration file into the Config::Options shape used by Nonnative.
  class ConfigurationFile
    class << self
      # Loads a file into a Config::Options instance.
      #
      # YAML files are parsed as data only: ERB is not evaluated and arbitrary object deserialization is not allowed.
      #
      # @param path [String] file path
      # @return [Config::Options]
      def load(path)
        Config::Options.new.tap do |config|
          config.add_source!(safe_load_yaml(path))
          config.load!
        end
      end

      private

      def safe_load_yaml(path)
        contents = File.read(path)
        config = YAML.safe_load(contents, aliases: true) || {}
        return config if config.is_a?(Hash)

        raise ArgumentError, "Configuration file '#{path}' must contain a YAML mapping"
      rescue Psych::SyntaxError => e
        raise ArgumentError, "YAML syntax error occurred while parsing #{path}: #{e.message}"
      end
    end
  end
end
