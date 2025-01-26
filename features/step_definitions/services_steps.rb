# frozen_string_literal: true

Given('I configure the system programmatically with services') do
  Nonnative.configure do |config|
    config.version = '1.0'
    config.url = 'http://localhost:4567'

    config.service do |s|
      s.name = 'service_1'
      s.host = '127.0.0.1'
      s.port = 20_006
      s.proxy = {
        kind: 'fault_injection',
        host: '127.0.0.1',
        port: 30_000,
        log: 'test/reports/proxy_service_1.log',
        wait: 1,
        options: {
          delay: 7
        }
      }
    end
  end
end

Given('I configure the system through configuration with services') do
  Nonnative.configure do |config|
    config.load_file('features/configs/services.yml')
  end

  expect(Nonnative.configuration.version).to eq('1.0')
  expect(Nonnative.configuration.url).to eq('http://localhost:4567')
end

When('I connect to the service') do
  @service = Nonnative::Features::Service.new(20_006)
end

When('I try to find the proxy for service {string}') do |name|
  Nonnative.pool.service_by_name(name)
rescue StandardError => e
  @error = e
end

Then('I should receive a connection error from the service') do
  expect(@service.receive).to be_nil
end

Then('I should have a succesful connection') do
  expect(@service).not_to be_closed
end
