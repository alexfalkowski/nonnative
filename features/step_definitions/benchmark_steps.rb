# frozen_string_literal: true

When('I configure the system programatially with a no op server') do
  Nonnative.configure do |config|
    config.server do |d|
      d.klass = Nonnative::Features::NoOpServer
      d.timeout = 1
      d.port = 14_000
    end
  end
end

When('I configure the system programatially with a no stop server') do
  Nonnative.configure do |config|
    config.server do |d|
      d.klass = Nonnative::Features::NoStopServer
      d.timeout = 1
      d.port = 14_001
    end
  end
end

Then('starting the system should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stoping the system should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end
