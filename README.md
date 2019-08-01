[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=svg)](https://circleci.com/gh/alexfalkowski/nonnative)

# Nonnative

Do you love building microservices using different languages?

Do you love testing applications using [cucumber](https://cucumber.io/) with [ruby](https://www.ruby-lang.org/en/)?

Well so do I. The issue is that most languages the cucumber implementation is not always complete or you have to write a lot of code to get it working.

So why not test the way you want and build the microservice how you want. These kind of tests will make sure your application is tested properly by going end-to-end.

The way it works is it spawns the process you configure and waits for it to start. Then you communicate with your microservice however you like (TCP, HTTP, gRPC, etc)

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

Configure nonnative with the process that you want to start, a timeout value and a port to verify it's working.

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.process = 'features/support/bin/start'
  config.timeout = 0.5
  config.port = 12_321
end
```

Tag your cucumber scenarios with @nonnative

```cucumber
Scenario: Successful Response
  When we send "test" with the echo client
  Then we should receive a "test" response
```
