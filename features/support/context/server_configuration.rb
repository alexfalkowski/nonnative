# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ServerConfiguration
        private

        def add_server(config, definition)
          config.server do |server|
            server.name = definition[:name]
            server.klass = resolve_klass(definition[:klass])
            server.timeout = definition[:timeout]
            server.host = definition[:host] if definition[:host]
            server.ports = definition[:ports]
            server.log = definition[:log]
          end
        end

        def resolve_klass(klass)
          return klass if klass.is_a?(Class)

          Object.const_get(klass)
        end
      end
    end
  end
end
