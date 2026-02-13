[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=shield)](https://circleci.com/gh/alexfalkowski/nonnative)
[![codecov](https://codecov.io/gh/alexfalkowski/nonnative/graph/badge.svg?token=4ISVHEZ72O)](https://codecov.io/gh/alexfalkowski/nonnative)
[![Gem Version](https://badge.fury.io/rb/nonnative.svg)](https://badge.fury.io/rb/nonnative)
[![Stability: Active](https://masterminds.github.io/stability/active.svg)](https://masterminds.github.io/stability/active.html)

# Nonnative

Nonnative is a Ruby-first harness for end-to-end testing of systems implemented in other languages.

It helps you:
- start **OS processes** (e.g. your Go/Java/Rust service binary),
- start **in-process Ruby servers** (e.g. small HTTP/TCP/gRPC fakes for dependencies),
- optionally start **proxies** in front of processes/servers/services for fault-injection,
- wait for readiness/shutdown using **TCP port checks**.

Once started, you can test however you like (TCP, HTTP, gRPC, etc).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nonnative'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install nonnative
```

## Usage

Nonnative is configured via {#Nonnative.configure} (programmatic) or `config.load_file(...)` (YAML).

High-level configuration fields:
- `version`: configuration version (example: `"1.0"`).
- `name`: logical system name (used by `Nonnative.observability` for `/<name>/healthz`, etc).
- `url`: base URL for observability queries (example: `http://localhost:4567`).
- `log`: path for the Nonnative logger output.
- `processes`: child processes to `spawn`.
- `servers`: in-process Ruby servers started in threads.
- `services`: external dependencies (proxy-only; no process/thread started by Nonnative).

Runner fields (process/server/service):
- `timeout`: max time (seconds) for readiness/shutdown port checks.
- `wait`: small sleep (seconds) between lifecycle steps.
- `host`/`port`: address used for port checks; when a proxy is enabled, reads happen via the proxy.
- `log`: per-runner log file (used by process output redirection or server implementations).

### Lifecycle strategies (Cucumber integration)

Nonnative ships Cucumber hooks (when loaded) that support these tags/strategies:
- `@startup`: start before scenario; stop after scenario
- `@manual`: stop after scenario (start is expected to be triggered manually in steps)
- `@clear`: clears memoized configuration and pool before scenario
- `@reset`: resets proxies after scenario

If you want “start once per test run”, require:

```ruby
require 'nonnative/startup'
```

This calls `Nonnative.start` immediately and registers an `at_exit` stop.

### Processes

A process is some sort of command that you would run locally.

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

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
name: test
url: http://localhost:4567
log: nonnative.log
processes:
  -
    name: start_1
    command: features/support/bin/start 12_321
    timeout: 5
    wait: 1
    port: 12321
    log: 12_321.log
    signal: INT # Possible values are described in Signal.list.keys.
    environment: # Pass environment variables to process.
      TEST: true
  -
    name: start_2
    command: features/support/bin/start 12_322
    timeout: 5
    wait: 1
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
  class TCPServer < Nonnative::Server
    def initialize(service)
      super

      @socket_server = ::TCPServer.new(proxy.host, proxy.port)
    end

    def perform_start
      loop do
        client_socket = socket_server.accept
        client_socket.puts 'Hello World!'
        client_socket.close
      end
    rescue StandardError
      socket_server.close
    end

    def perform_stop
      socket_server.close
    end

    private

    attr_reader :socket_server
  end
end
```

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

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
name: test
url: http://localhost:4567
log: nonnative.log
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
    class Hello < Sinatra::Application
      get '/hello' do
        'Hello World!'
      end
    end

    class HTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super(Sinatra.new(Hello), service)
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
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

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
name: test
url: http://localhost:4567
log: nonnative.log
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

##### Proxy

The system allows you to define a http proxy for external systems, e.g api.github.com

Define your server:

```ruby
module Nonnative
  module Features
    class HTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('www.afalkowski.com', service)
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
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.server do |s|
    s.name = 'http_server_proxy'
    s.klass = Nonnative::Features::HTTPProxyServer
    s.timeout = 1
    s.port = 4567
    s.log = 'http_server_proxy.log'
  end
end
```

Setup it up through configuration:

```yaml
version: "1.0"
name: test
url: http://localhost:4567
log: nonnative.log
servers:
  -
    name: http_server_proxy
    class: Nonnative::Features::HTTPProxyServer
    timeout: 1
    port: 4567
    log: http_server_proxy.log
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
      def initialize(service)
        super(Greeter.new, service)
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
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

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
name: test
url: http://localhost:4567
log: nonnative.log
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

A service is an external dependency to your system that you **do not** want Nonnative to start (no OS process, no Ruby thread). Services are primarily useful when paired with proxies, because they let you inject failures into dependencies that are managed elsewhere (e.g. a DB running in Docker).

Set it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.service do |s|
    s.name = 'postgres'
    s.host = '127.0.0.1'
    s.port = 5432
  end

  config.service do |s|
    s.name = 'redis'
    s.host = '127.0.0.1'
    s.port = 6379
  end
end
```

Set it up through configuration (YAML):

```yaml
version: "1.0"
name: test
url: http://localhost:4567
log: nonnative.log
services:
  -
    name: postgres
    host: 127.0.0.1
    port: 5432
  -
    name: redis
    host: 127.0.0.1
    port: 6379
```

Then load the file with:

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

##### Proxies Processes

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.process do |p|
    p.proxy = {
      kind: 'fault_injection',
      port: 20_000,
      log: 'proxy_server.log',
      wait: 1,
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
name: test
url: http://localhost:4567
log: nonnative.log
processes:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      wait: 1
      options:
        delay: 5
```

##### Proxies Servers

Setup it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.server do |s|
    s.proxy = {
      kind: 'fault_injection',
      port: 20_000,
      log: 'proxy_server.log',
      wait: 1,
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
name: test
url: http://localhost:4567
log: nonnative.log
servers:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      wait: 1
      options:
        delay: 5
```

##### Proxies Services

Set it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.service do |s|
    s.name = 'redis'
    s.host = '127.0.0.1'
    s.port = 6379

    s.proxy = {
      kind: 'fault_injection',
      host: '127.0.0.1',
      port: 20_000,
      log: 'proxy_server.log',
      wait: 1,
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
name: test
url: http://localhost:4567
log: nonnative.log
wait: 1
services:
  -
    proxy:
      kind: fault_injection
      port: 20000
      log: proxy_server.log
      wait: 1
      options:
        delay: 5
```

##### Fault Injection

The `fault_injection` proxy allows you to simulate failures by injecting them. We currently support the following:

- `close_all` - Closes the socket as soon as it connects.
- `delay` - This delays the communication between the connection. Default is 2 secs can be configured through options.
- `invalid_data` - This takes the input and rearranges it to produce invalid data.

###### Fault Injection Processes

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

###### Fault Injection Servers

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

###### Fault Injection Services

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
name: test
url: http://localhost:4567
log: nonnative.log
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
