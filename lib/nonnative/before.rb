# frozen_string_literal: true

require 'cucumber'

Before do
  Nonnative.start
end

After do
  Nonnative.stop
end
