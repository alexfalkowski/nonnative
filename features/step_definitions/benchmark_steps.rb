# frozen_string_literal: true

Then('starting nonnative should happen with an adequate time') do
  expect { Nonnative.start }.to perform_under(2).sec
  Nonnative.stop
end

Then('stoping nonnative should happen with an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end
