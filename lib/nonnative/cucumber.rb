# frozen_string_literal: true

Before('@nonnative') do
  Nonnative.start
end

After('@nonnative') do
  Nonnative.stop
end
