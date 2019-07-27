# Nonnative

Allows you to keep using the power of ruby to test other systems

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

Configure the system withh the process and how long we give to wait until it's ready

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.process = 'features/support/bin/start'
  config.wait = 0.5
end
```

Tag your cucumber scenarios with @nonnative

```cucumber
@nonnative
Scenario: Successful Response
  When we send "test" with the echo client
  Then we should receive a "test" response
```

## Development

Look at the Makefile

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nonnative.
