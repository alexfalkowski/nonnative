# frozen_string_literal: true

When('I configure nonnative through configuration with processes') do
  Nonnative.load_configuration('features/processes.yml')
end

Then('starting nonnative should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stoping nonnative should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end
