[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=shield)](https://circleci.com/gh/alexfalkowski/nonnative)
[![codecov](https://codecov.io/gh/alexfalkowski/nonnative/graph/badge.svg?token=4ISVHEZ72O)](https://codecov.io/gh/alexfalkowski/nonnative)
[![Gem Version](https://badge.fury.io/rb/nonnative.svg)](https://badge.fury.io/rb/nonnative)
[![Stability: Active](https://masterminds.github.io/stability/active.svg)](https://masterminds.github.io/stability/active.html)

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

- The version of the configuration (1.0).
- The URL of the service.
- The time to wait on proxy changes (fault injection).
- Process, Server or Service that you want to start.
- A timeout value.
- A time to wait.
- Port to verify.
- The class for servers.
- The log for servers/processes
- The strategy for processes, servers and services.

### Strategy

The strategy can be one of the following values:
- startup - When we include `nonnative/startup`, it will start it once.
- before - When we tag our features with `@startup` it will start and stop after the scenario.
- manual - When we tag our features with `@manual` it will stop after the scenario.

### Processes

A process is some sort of command that you would run locally.

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'
  config.wait = 2.0

  config.process do |p|
    p.name = 'start_1'
    p.command = -> { 'features/support/bin/start 12_321' }
    p.timeout = 5
    p.wait = 0.1
    p.port = 12_321
    p.log = '12_321.log'
    p.signal = 'INT' # Possible values are described in Signal.list.keys.
    p.environment = { # Pass environment variables to process.
      'TEST' => 'true'
    }
  end

  config.process do |p|
    p.name = 'start_2'
    p.command = -> { 'features/support/bin/start 12_322' }
    p.timeout = 0.5
    p.wait = 0.1
    p.port = 12_322
    p.log = '12_322.log'
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
wait: 2.0
processes:
  -
    name: start_1
    command: features/support/bin/start 12_321
    timeout: 5
    wait: 0.1
    port: 12321
    log: 12_321.log
    signal: INT # Possible values are described in Signal.list.keys.
    environment: # Pass environment variables to process.
      TEST: true
  -
    name: start_2
    command: features/support/bin/start 12_322
    timeout: 5
    wait: 0.1
    port: 12322
    log: 12_322.log
```

Then load the file with

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

With cucumber you can also verify how much memory is used by the process:

```cucumber
Then the process 'start_1' should consume less than '25mb' of memory
```

### Servers

A server is a dependency to some external API.

Define your server:

```ruby
module Nonnative
  class EchoServer < Nonnative::Server
    def perform_start
      @socket_server = TCPServer.new(service.host, service.port)

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
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.server do |s|
    s.name = 'server_1'
    s.klass = Nonnative::EchoServer
    s.timeout = 1
    s.port = 12_323
    s.log = 'server_1.log'
  end

  config.server do |s|
    s.name = 'server_2'
    s.klass = Nonnative::EchoServer
    s.timeout = 1
    s.port = 12_324
    s.log = 'server_2.log'
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
servers:
  -
    name: server_1
    class: Nonnative::EchoServer
    timeout: 1
    port: 12323
    log: server_1.log
  -
    name: server_2
    class: Nonnative::EchoServer
    timeout: 1
    port: 12324
    log: server_2.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
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
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.server do |s|
    s.name = 'http_server_1'
    s.klass = Nonnative::Features::HTTPServer
    s.timeout = 1
    s.port = 4567
    s.log = 'http_server_1.log'
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
servers:
  -
    name: http_server_1
    class: Nonnative::Features::HTTPServer
    timeout: 1
    port: 4567
    log: http_server_1.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

#### gRPC

Define your server:

```ruby
module Nonnative
  module Features
    class Greeter < GreeterService::Service
      def say_hello(request, _call)
        Nonnative::Features::SayHelloResponse.new(message: request.name.to_s)
      end
    end

    class GRPCServer < Nonnative::GRPCServer
      def svc
        Greeter.new
      end
    end
  end
end
```

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.server do |s|
    s.name = 'grpc_server_1'
    s.klass = Nonnative::Features::GRPCServer
    s.timeout = 1
    s.port = 9002
    s.log = 'grpc_server_1.log'
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
servers:
  -
    name: grpc_server_1
    class: Nonnative::Features::GRPCServer
    timeout: 1
    port: 9002
    log: grpc_server_1.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

### Services

A service is an external dependency to your system. This is usually an expensive process to start like a DB and you would prefer to be managed externally. Services are not really exciting by themselves, it's when we add proxies that they allow us to do some extra work.

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.service do |s|
    s.name = 'postgres'
    p.port = 5432
  end

  config.service do |s|
    s.name = 'redis'
    s.port = 6379
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
processes:
  -
    name: postgres
    port: 5432
  -
    name: redis
    port: 6379
```

Then load the file with

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

#### Proxies

We allow different proxies to be configured. These proxies can be used to simulate all kind of situations. The proxies that can be configured are:
- `none` (this is the default)
- `fault_injection`

##### Processes

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.process do |p|
    p.proxy = {
      kind: 'fault_injection',
      port: 20_000,
      log: 'proxy_server.log',
      options: {
        delay: 5
      }
    }
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
processes:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      options:
        delay: 5
```

##### Servers

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.server do |s|
    s.proxy = {
      kind: 'fault_injection',
      port: 20_000,
      log: 'proxy_server.log',
      options: {
        delay: 5
      }
    }
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
servers:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      options:
        delay: 5
```

##### Services

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.url = 'http://localhost:4567'

  config.service do |s|
    s.proxy = {
      kind: 'fault_injection',
      port: 20_000,
      log: 'proxy_server.log',
      options: {
        delay: 5
      }
    }
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
services:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      options:
        delay: 5
```

##### Fault Injection

The `fault_injection` proxy allows you to simulate failures by injecting them. We currently support the following:
- `close_all` - Closes the socket as soon as it connects.
- `delay` - This delays the communication between the connection. Default is 2 secs can be configured through options.
- `invalid_data` - This takes the input and rearranges it to produce invalid data.

###### Processes

Setup it up programmatically:

```ruby
name = 'name of process in configuration'
server = Nonnative.pool.process_by_name(name)

server.proxy.close_all # To use close_all.
server.proxy.reset # To reset it back to a good state.
```

With cucumber:

```cucumber
Given I set the proxy for process 'process_1' to 'close_all'
Then I should reset the proxy for process 'process_1'
```

###### Servers

Setup it up programmatically:

```ruby
name = 'name of server in configuration'
server = Nonnative.pool.server_by_name(name)

server.proxy.close_all # To use close_all.
server.proxy.reset # To reset it back to a good state.
```

With cucumber:

```cucumber
Given I set the proxy for server 'server_1' to 'close_all'
Then I should reset the proxy for server 'server_1'
```

###### Services

Setup it up programmatically:

```ruby
name = 'name of service in configuration'
service = Nonnative.pool.service_by_name(name)

service.proxy.close_all # To use close_all.
service.proxy.reset # To reset it back to a good state.
```

With cucumber:

```cucumber
Given I set the proxy for service 'service_1' to 'close_all'
Then I should reset the proxy for service 'service_1'
```

### Go

As we love using go as a language for services we have added support to start binaries with defined parameters. This expects that you build your services in the format of `command sub_command --params`

To get this to work you will need to create a `main_test.go` file with these contents:

```go
// +build features

package main

import "testing"

func TestFeatures(t *testing.T) {
	main()
}
```

Then to compile this binary you will need to do the following:

```sh
go test -mod vendor -c -tags features -covermode=count -o your_binary -coverpkg=./... github.com/your_location
```

Setup it up programmatically:

```ruby
tools = %w[prof trace cover]

Nonnative.go_executable(tools, 'reports', 'your_binary', 'sub_command', '--config config.yaml')
```

Setup it up through configuration:

```yaml
version: "1.0"
url: http://localhost:4567
processes:
  -
    name: go
    go:
      tools: [prof, trace, cover]
      output: reports
      executable: your_binary
      command: sub_command
      parameters:
        - --config config.yaml
    timeout: 5
    port: 8000
    log: go.log
```
