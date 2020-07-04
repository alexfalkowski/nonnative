[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=svg)](https://circleci.com/gh/alexfalkowski/nonnative)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=alexfalkowski_nonnative&metric=alert_status)](https://sonarcloud.io/dashboard?id=alexfalkowski_nonnative)

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

- Process/Server that you want to start.
- A timeout value.
- Port to verify.
- The class for servers.
- The file you want STDOUT to be logged to for processes.
- The strategy for processes/servers.
  * Startup will start the process once.
  * Before will hook into cucumbers Before and After.

### Processes

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :startup or :before or :manual

  config.process do |d|
    d.name = 'start_1'
    d.command = 'features/support/bin/start 12_321'
    d.timeout = 0.5
    d.port = 12_321
    d.file = 'features/logs/12_321.log'
    d.signal = 'INT' # Possible values are described in Signal.list.keys
  end

  config.process do |d|
    d.name = 'start_2'
    d.command = 'features/support/bin/start 12_322'
    d.timeout = 0.5
    d.port = 12_322
    d.file = 'features/logs/12_322.log'
  end
end
```

Setup it up through configuration:

```yaml
version: 1.0
strategy: manual
processes:
  -
    name: start_1
    command: features/support/bin/start 12_321
    timeout: 5
    port: 12321
    file: features/logs/12_321.log
    signal: INT # Possible values are described in Signal.list.keys
  -
    name: start_2
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

### Servers

Define your server:

```ruby
module Nonnative
  class EchoServer < Nonnative::Server
    def perform_start
      @socket_server = TCPServer.new('0.0.0.0', port)

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
    d.name = 'server_1'
    d.klass = Nonnative::EchoServer
    d.timeout = 1
    d.port = 12_323
  end

  config.server do |d|
    d.name = 'server_2'
    d.klass = Nonnative::EchoServer
    d.timeout = 1
    d.port = 12_324
  end
end
```

Setup it up through configuration:

```yaml
version: 1.0
strategy: manual
servers:
  -
    name: server_1
    klass: Nonnative::EchoServer
    timeout: 1
    port: 12323
  -
    name: server_2
    klass: Nonnative::EchoServer
    timeout: 1
    port: 12324
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```

#### HTTP

Define your server:

```ruby
module Nonnative
  module Features
    class Application < Sinatra::Base
      get '/hello' do
        'Hello World!'
      end
    end

    class HTTPServer < Nonnative::HTTPServer
      def app
        Application.new
      end
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
    d.name = 'http_server_1'
    d.klass = Nonnative::Features::HTTPServer
    d.timeout = 1
    d.port = 4567
  end
end
```

Setup it up through configuration:

```yaml
version: 1.0
strategy: manual
servers:
  -
    name: http_server_1
    klass: Nonnative::Features::HTTPServer
    timeout: 1
    port: 4567
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```

#### gRPC

Define your server:

```ruby
module Nonnative
  module Features
    class GreeterService < Greeter::Service
      def say_hello(request, _call)
        Nonnative::Features::HelloReply.new(message: request.name.to_s)
      end
    end

    class GRPCServer < Nonnative::GRPCServer
      def svc
        GreeterService.new
      end
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
    d.name = 'grpc_server_1'
    d.klass = Nonnative::Features::GRPCServer
    d.timeout = 1
    d.port = 9002
  end
end
```

Setup it up through configuration:

```yaml
version: 1.0
strategy: manual
servers:
  -
    name: grpc_server_1
    klass: Nonnative::Features::GRPCServer
    timeout: 1
    port: 9002
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```
#### Proxies

We allow different proxies to be configured. These proxies can be used to simulate all kind of situations. The proxies that can be configured are:
- none (this is the default)
- chaos

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :manual

  config.server do |d|
    d.proxy.type = 'chaos'
    d.proxy.port = 20_000
  end
end
```

Setup it up through configuration:

```yaml
version: 1.0
strategy: manual
servers:
  -
    proxy:
      type: chaos
      port: 20000
```
