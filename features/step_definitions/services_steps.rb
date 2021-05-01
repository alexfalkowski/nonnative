# frozen_string_literal: true

Given('I configure nonnative programatically with services') do
  Nonnative.configure do |config|
    config.strategy = :manual

    config.service do |s|
      s.name = 'service_1'
      s.port = 20_006
      s.proxy = {
        type: 'fault_injection',
        port: 30_000,
        log: 'features/logs/proxy_service_1.log',
        options: {
          delay: 7
        }
      }
    end
  end
end

Given('I configure nonnative through configuration with services') do
  Nonnative.load_configuration('features/configs/services.yml')
end

When('I connect to the service') do
  @service = Nonnative::Features::Service.new(20_006)
end

Then('I should receive a connection error from the service') do
  expect(@service.receive).to be_nil
end

Then('I should have a succesful connection') do
  expect(@service).not_to be_closed
end
