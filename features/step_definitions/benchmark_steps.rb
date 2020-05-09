# frozen_string_literal: true

When('I configure nonnative through configuration with processes') do
  Nonnative.load_configuration('features/processes.yml')
end

When('I configure nonnative programatially with a no op server') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |d|
      d.klass = Nonnative::Features::NoOpServer
      d.timeout = 1
      d.port = 14_000
    end
  end
end

When('I configure nonnative programatially with a no stop server') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.server do |d|
      d.klass = Nonnative::Features::NoStopServer
      d.timeout = 1
      d.port = 14_001
    end
  end
end

Then('starting nonnative should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stoping nonnative should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end

Then('starting nonnative should raise an error') do
  expect { Nonnative.start }.to raise_error(Nonnative::StartError)
end

Then('stopping nonnative should raise an error') do
  expect { Nonnative.stop }.to raise_error(Nonnative::StopError)
end
