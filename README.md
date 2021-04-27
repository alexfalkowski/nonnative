[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=svg)](https://circleci.com/gh/alexfalkowski/nonnative)
[![Coverage Status](https://coveralls.io/repos/github/alexfalkowski/nonnative/badge.svg?branch=master)](https://coveralls.io/github/alexfalkowski/nonnative?branch=master)

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
- The log for servers/processes
- The strategy for processes/servers.

### Strategy

The strategy can be one of the following values:
- startup - will start the process once.
- before - will hook into cucumbers Before and After.
- manual - do this manually

This can be overridden by the following environment variables:
- NONNATIVE_STRATEGY - Set this to override what is set in the config.
- NONNATIVE_TIMEOUT - Set this (in seconds, e.g 5) to override what is set in the config.

### Processes

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :startup

  config.process do |d|
    d.name = 'start_1'
    d.command = 'features/support/bin/start 12_321'
    d.timeout = config.strategy.timeout
    d.port = 12_321
    d.log = 'features/logs/12_321.log'
    d.signal = 'INT' # Possible values are described in Signal.list.keys
  end

  config.process do |d|
    d.name = 'start_2'
    d.command = 'features/support/bin/start 12_322'
    d.timeout = 0.5
    d.port = 12_322
    d.log = 'features/logs/12_322.log'
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
    log: features/logs/12_321.log
    signal: INT # Possible values are described in Signal.list.keys
  -
    name: start_2
    command: features/support/bin/start 12_322
    timeout: 5
    port: 12322
    log: features/logs/12_322.log
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

  config.server do |s|
    s.name = 'server_1'
    s.klass = Nonnative::EchoServer
    s.timeout = 1
    s.port = 12_323
    s.log = 'features/logs/server_1.log'
  end

  config.server do |s|
    s.name = 'server_2'
    s.klass = Nonnative::EchoServer
    s.timeout = 1
    s.port = 12_324
    s.log = 'features/logs/server_2.log'
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
    log: features/logs/server_1.log
  -
    name: server_2
    klass: Nonnative::EchoServer
    timeout: 1
    port: 12324
    log: features/logs/server_2.log
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
    class Application < Sinatra::Application
      configure do
        set :server_settings, log_requests: true
      end

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

  config.server do |s|
    s.name = 'http_server_1'
    s.klass = Nonnative::Features::HTTPServer
    s.timeout = 1
    s.port = 4567
    s.log = 'features/logs/http_server_1.log'
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
    log: features/logs/http_server_1.log
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

  config.server do |s|
    s.name = 'grpc_server_1'
    s.klass = Nonnative::Features::GRPCServer
    s.timeout = 1
    s.port = 9002
    s.log = 'features/logs/grpc_server_1.log'
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
    log: features/logs/grpc_server_1.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.load_configuration('configuration.yml')
```
#### Proxies

We allow different proxies to be configured. These proxies can be used to simulate all kind of situations. The proxies that can be configured are:
- `none` (this is the default)
- `fault_injection`

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.strategy = :manual

  config.server do |d|
    d.proxy = {
      type: 'fault_injection',
      port: 20_000,
      log: 'features/logs/proxy_server.log',
      options: {
        delay: 5
      }
    }
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
      type: fault_injection
      port: 20000
      log: features/logs/proxy_server.log
      options:
        delay: 5
```

##### Fault Injection

The `fault_injection` proxy allows you to simulate failures by injecting them. We currently support the following:
- `close_all` - Closes the socket as soon as it connects.
- `delay` - This delays the communication between the connection. Default is 2 secs can be configured through options.
- `invalid_data` - This takes the input and rearranges it to produce invalid data.

Setup it up programmatically:

```ruby
name = 'name of server in configuration'
server = Nonnative.pool.server_by_name(name)

server.proxy.close_all # To use close_all.
server.proxy.reset # To reset it back to a good state.
```

### Go

As we love using go as a language for services we have added support to start binaries with defined parameters. This expects that you build your services in the format of `command sub_command --params`

To get this to work you will need to create a `main_test.go` file with these contents:

```go
// +build features

package main

import (
	"testing"

	"github.com/your_location/cmd"
)

func TestFeatures(t *testing.T) {
	if err := cmd.Execute(); err != nil {
		t.Fatal(err.Error())
	}
}
```

Then to compile this binary you will need to do the following:

```sh
go test -mod vendor -c -tags features -covermode=count -o your_binary -coverpkg=./... github.com/your_location
```

Then to get an executable you do the following:

```ruby
Nonnative.go_executable('reports', 'your_binary', 'sub_command', '--config config.yaml')
```
