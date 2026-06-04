# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ConfigurationFiles
        def load_temporary_configuration(contents)
          path = "test/reports/#{SecureRandom.hex(4)}.yml"
          File.write(path, contents)

          load_configuration(path)
        end

        def malformed_yaml(kind)
          case kind
          when 'scalar root'
            'not a mapping'
          when 'syntax error'
            "name: [unterminated\n"
          else
            raise ArgumentError, "Unknown malformed YAML kind '#{kind}'"
          end
        end
      end
    end
  end
end
