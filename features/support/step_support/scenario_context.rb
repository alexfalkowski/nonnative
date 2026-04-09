# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module ScenarioContext
        def configure_with_defaults(url: DEFAULT_URL, log: DEFAULT_LOG)
          Nonnative.configure do |config|
            config.version = DEFAULT_VERSION
            config.name = DEFAULT_NAME
            config.url = url
            config.log = log

            yield config
          end
        end

        def load_configuration(path)
          Nonnative.configure do |config|
            config.load_file(path)
          end
        end

        def capture_result(result_ivar = :@response, error_ivar = :@error)
          instance_variable_set(result_ivar, nil)
          instance_variable_set(error_ivar, nil)
          instance_variable_set(result_ivar, yield)
        rescue StandardError => e
          instance_variable_set(error_ivar, e)
        end
      end
    end
  end
end
