# frozen_string_literal: true

When('I configure nonnative through configuration') do
  Nonnative.load_configuration('features/configuration.yml')
end

Then('starting nonnative should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
ensure
  Nonnative.stop
end

Then('stoping nonnative should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end
