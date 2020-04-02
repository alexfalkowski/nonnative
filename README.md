[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=svg)](https://circleci.com/gh/alexfalkowski/nonnative)

# Nonnative

Do you love building microservices using different languages?

Do you love testing applications using [cucumber](https://cucumber.io/) with [ruby](https://www.ruby-lang.org/en/)?

Well so do I. The issue is that most languages the cucumber implementation is not always complete or you have to write a lot of code to get it working.

So why not test the way you want and build the microservice how you want. These kind of tests will make sure your application is tested properly by going end-to-end.

The way it works is it spawns processes or servers you configure and waits for it to start. Then you communicate with your microservice however you like (TCP, HTTP, gRPC, etc)

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

We can start a process, server or both.

#### Processes

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :startup or :before or :manual

  config.process do |d|
    d.command = 'features/support/bin/start 12_321'
    d.timeout = 0.5
    d.port = 12_321
    d.file = 'features/logs/12_321.log'
  end

  config.process do |d|
    d.command = 'features/support/bin/start 12_322'
    d.timeout = 0.5
    d.port = 12_322
    d.file = 'features/logs/12_322.log'
  end
end
```

Setup it up through configuration:

### YAML

```yaml
version: 1.0
strategy: manual
processes:
  -
    command: features/support/bin/start 12_321
    timeout: 5
    port: 12321
    file: features/logs/12_321.log
  -
    command: features/support/bin/start 12_322
    timeout: 5
    port: 12322
    file: features/logs/12_322.log
```

Then load the file with

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```

#### Servers

Define your server:

```ruby
module Nonnative
  class EchoServer < Nonnative::Server
    def perform_start
      @socket_server = TCPServer.new('127.0.0.1', port)

      loop do
        client_socket = @socket_server.accept
        client_socket.puts 'Hello World!'
        client_socket.close
      end
    rescue StandardError
    end

    def perform_stop
      @socket_server.close
    end
  end
end
```

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :manual

  config.server do |d|
    d.klass = Nonnative::EchoServer
    d.timeout = 1
    d.port = 12_323
  end

  config.server do |d|
    d.klass = Nonnative::EchoServer
    d.timeout = 1
    d.port = 12_324
  end
end
```

Setup it up through configuration:

### YAML

```yaml
version: 1.0
strategy: manual
servers:
  -
    klass: Nonnative::EchoServer
    timeout: 1
    port: 12323
  -
    klass: Nonnative::EchoServer
    timeout: 1
    port: 12324
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```
