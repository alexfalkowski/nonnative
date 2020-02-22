[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=svg)](https://circleci.com/gh/alexfalkowski/nonnative)

# Nonnative

Do you love building microservices using different languages?

Do you love testing applications using [cucumber](https://cucumber.io/) with [ruby](https://www.ruby-lang.org/en/)?

Well so do I. The issue is that most languages the cucumber implementation is not always complete or you have to write a lot of code to get it working.

So why not test the way you want and build the microservice how you want. These kind of tests will make sure your application is tested properly by going end-to-end.

The way it works is it spawns the processes you configure and waits for it to start. Then you communicate with your microservice however you like (TCP, HTTP, gRPC, etc)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nonnative'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nonnative

## Usage

Configure nonnative with the following:

- Process that you want to start.
- A timeout value.
- Port to verify.
- The file you want STDOUT to be logged to.
- The strategy (Startup will start the process once and before will hook into cucumbers Before and After).

### Ruby

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :startup or :before or :manual

  config.definition do |d|
    d.process = 'features/support/bin/start 12_321'
    d.timeout = 0.5
    d.port = 12_321
    d.file = 'features/logs/12_321.log'
  end

  config.definition do |d|
    d.process = 'features/support/bin/start 12_322'
    d.timeout = 0.5
    d.port = 12_322
    d.file = 'features/logs/12_322.log'
  end
end
```

### YAML

```yaml
version: 1.0
strategy: manual
definitions:
  -
    process: features/support/bin/start 12_321
    timeout: 5
    port: 12321
    file: features/logs/12_321.log
  -
    process: features/support/bin/start 12_322
    timeout: 5
    port: 12322
    file: features/logs/12_322.log
```

Then load the file with

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```
