# frozen_string_literal: true

# Starts the configured Nonnative pool immediately and registers an `at_exit` stop hook.
#
# Configure Nonnative before requiring this file; it is intended for suites that keep one
# Nonnative lifecycle open for the whole Ruby process.

at_exit do
  Nonnative.stop
end

Nonnative.start
