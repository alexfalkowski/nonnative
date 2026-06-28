[![CircleCI](https://circleci.com/gh/alexfalkowski/nonnative.svg?style=shield)](https://circleci.com/gh/alexfalkowski/nonnative)
[![codecov](https://codecov.io/gh/alexfalkowski/nonnative/graph/badge.svg?token=4ISVHEZ72O)](https://codecov.io/gh/alexfalkowski/nonnative)
[![Gem Version](https://badge.fury.io/rb/nonnative.svg)](https://badge.fury.io/rb/nonnative)
[![Stability: Active](https://masterminds.github.io/stability/active.svg)](https://masterminds.github.io/stability/active.html)

# 🧪 Nonnative

Nonnative is a Ruby-first harness for end-to-end testing of systems implemented in other languages.

It helps you:
- start **OS processes** (e.g. your Go/Java/Rust service binary),
- start **in-process Ruby servers** (e.g. small HTTP/TCP/gRPC fakes for dependencies),
- optionally start **service proxies** for fault-injection in front of externally managed dependencies,
- wait for readiness/shutdown using **TCP port checks**.

Once started, you can test however you like (TCP, HTTP, gRPC, etc).

## 📦 Installation

> [!IMPORTANT]
> Nonnative currently supports Ruby `>= 4.0.0` and `< 5.0.0`.

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

## 🛠️ Contributor Bootstrap

Fresh clones need the shared `bin/` submodule before Make targets can load:

```bash
git submodule sync && git submodule update --init
make help
```

Use `make dep` before local validation when dependencies are missing. The CI-parity checks are
`make lint`, `make sec`, `make features`, and `make benchmarks`.

## 🚀 Usage

Nonnative is configured via `Nonnative.configure` (programmatic) or `config.load_file(...)` (YAML).
YAML configuration is loaded as data only: ERB is not evaluated and arbitrary Ruby objects are not
deserialized.

> [!CAUTION]
> Treat YAML configuration as plain data. ERB is not evaluated and arbitrary Ruby object tags are rejected.

High-level configuration fields:
- `version`: configuration version (example: `"1.0"`).
- `name`: logical system name (used by `Nonnative.observability` for `/<name>/healthz`, etc).
- `url`: base URL for observability queries (example: `http://localhost:4567`).
- `log`: path for the Nonnative logger output.
- `processes`: child processes to `spawn`.
- `servers`: in-process Ruby servers started in threads.
- `services`: external dependencies (no process/thread started by Nonnative).

Common runner fields:
- `name`: runner name used for lookup.
- `host`: client-facing host. Defaults to `127.0.0.1`.

Process/server fields:
- `ports`: client-facing ports. These are also used for readiness/shutdown port checks.
- `timeout`: max time (seconds) for readiness/shutdown port checks. Defaults to `1.0`.
- `wait`: small sleep (seconds) between lifecycle steps.
- `log`: per-runner log file used by process output redirection or server implementations.

Process-only fields:
- `readiness`: optional HTTP startup readiness check with explicit `port` and path-only `path`.

Service fields:
- `port`: client-facing service port. Services do not get TCP readiness/shutdown checks from Nonnative.

Nonnative readiness and shutdown checks are TCP port checks by default. Configure process/server ports that are dedicated to the test run; if another process is already listening on the same endpoint, results are undefined. Processes can also opt into an HTTP readiness check that runs after TCP readiness succeeds. HTTP readiness paths must be path-only values, such as `/test/readyz`; absolute URLs and scheme-relative URLs are rejected.

> [!WARNING]
> TCP readiness and shutdown checks only prove that a TCP port opened or closed. HTTP readiness is process-only, checks for a 2xx response, and does not verify gRPC health, schema readiness, migrations, or other application-specific health.

Start and stop Nonnative around the test scope that should own the configured runners:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end

Nonnative.start
# run tests...
Nonnative.stop
```

`Nonnative.start` starts services first, then servers and processes. `Nonnative.stop` stops processes and servers first, then services. If startup fails, Nonnative rolls back runners that already started and raises `Nonnative::StartError`; shutdown failures raise `Nonnative::StopError`.

> [!NOTE]
> `Nonnative.start` / `Nonnative.stop` manage one lifecycle for the current pool.
> Call `Nonnative.clear` before reconfiguring Nonnative or starting a new lifecycle in the same Ruby process.
> `Nonnative.clear` clears memoized configuration, logger, observability client, and pool.

### 🧩 Test framework setup

For Cucumber, load and configure Nonnative in `features/support/env.rb`, then use lifecycle tags on scenarios:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

```cucumber
@startup
Scenario: run with Nonnative around this scenario
```

For RSpec or another suite that should start Nonnative once per test run, configure first and then require the startup integration:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end

require 'nonnative/startup'
```

`nonnative/startup` calls `Nonnative.start` immediately and registers an `at_exit` stop, so load configuration before requiring it.

### 📈 Observability

`Nonnative.observability` is an HTTP client for common service endpoints under the configured `name` and `url`:

- `health(...)`: calls `/<name>/healthz`.
- `liveness(...)`: calls `/<name>/livez`.
- `readiness(...)`: calls `/<name>/readyz`.
- `metrics(...)`: calls `/<name>/metrics`.

Each method accepts RestClient options such as `headers`, `open_timeout`, and `read_timeout`.

```ruby
response = Nonnative.observability.health(
  headers: { content_type: :json, accept: :json },
  open_timeout: 2,
  read_timeout: 2
)

expect(response.code).to eq(200)
```

### 🔁 Lifecycle strategies (Cucumber integration)

Nonnative ships Cucumber hooks (when loaded) that support these tags/strategies:
- `@startup`: start before scenario; stop after scenario
- `@manual`: stop after scenario; use `When I start the system` to start manually
- `@clear`: clears memoized configuration, logger, observability client, and pool before scenario
- `@reset`: resets proxies after scenario

The repo’s own Cucumber suite also uses taxonomy tags to classify coverage:
- `@acceptance`: end-to-end behavior across configured runners and clients
- `@contract`: lower-level contract and lifecycle behavior
- `@proxy`: proxy-specific behavior and failure injection
- `@config`: coverage that exercises YAML/config loading
- `@service`: scenarios centered on externally managed dependencies
- `@benchmark`: benchmark-only scenarios run by `make benchmarks`
- `@slow`: slower scenarios, currently used by benchmark coverage

`make features` excludes `@benchmark`, while `make benchmarks` runs only `@benchmark`.

Requiring `nonnative` is enough; the Cucumber hooks and step definitions are installed lazily once Cucumber’s Ruby DSL is ready.

### ⚙️ Processes

A process is some sort of command that you would run locally.
Programmatic `p.command` values must be callables that return a shell string or an argv array. YAML `command` values can be scalars or lists and are wrapped internally. String commands preserve legacy shell semantics, while argv arrays avoid shell interpretation and are preferred for new configuration.

> [!TIP]
> Prefer argv arrays for new process commands. Use shell strings only when you intentionally need shell parsing, expansion, or redirection.

Set it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.process do |p|
    p.name = 'start_1'
    p.command = -> { ['bin/start-test-service', '12_321'] }
    p.timeout = 5
    p.wait = 0.1
    p.ports = [12_321]
    p.log = '12_321.log'
    p.signal = 'INT' # Possible values are described in Signal.list.keys.
    p.readiness = { port: 12_321, path: '/test/readyz' }
    p.environment = { # Pass environment variables to process.
      'TEST' => 'true'
    }
  end

  config.process do |p|
    p.name = 'start_2'
    p.command = -> { ['bin/start-test-service', '12_322'] }
    p.timeout = 0.5
    p.wait = 0.1
    p.ports = [12_322]
    p.log = '12_322.log'
  end
end
```

Set it up through configuration:

```yaml
version: "1.0"
name: test
url: http://localhost:4567
log: nonnative.log
processes:
  -
    name: start_1
    command:
      - bin/start-test-service
      - "12_321"
    timeout: 5
    wait: 1
    ports:
      - 12321
    log: 12_321.log
    signal: INT # Possible values are described in Signal.list.keys.
    readiness:
      port: 12321
      path: /test/readyz
    environment: # Pass environment variables to process.
      TEST: true
  -
    name: start_2
    command:
      - bin/start-test-service
      - "12_322"
    timeout: 5
    wait: 1
    ports:
      - 12322
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

### 🖥️ Servers

A server is an in-process Ruby fake or helper server that Nonnative starts in a thread. Use servers for dependencies that are easiest to model inside the test process, such as small TCP, HTTP, or gRPC fakes.

Define your server:

```ruby
module Nonnative
  class TCPServer < Nonnative::Server
    def initialize(service)
      super

      @socket_server = ::TCPServer.new(service.host, service.port)
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

Set it up programmatically:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.version = '1.0'
  config.name = 'test'
  config.url = 'http://localhost:4567'
  config.log = 'nonnative.log'

  config.server do |s|
    s.name = 'server_1'
    s.klass = Nonnative::TCPServer
    s.timeout = 1
    s.ports = [12_323]
    s.log = 'server_1.log'
  end

  config.server do |s|
    s.name = 'server_2'
    s.klass = Nonnative::TCPServer
    s.timeout = 1
    s.ports = [12_324]
    s.log = 'server_2.log'
  end
end
```

Set it up through configuration:

```yaml
version: "1.0"
name: test
url: http://localhost:4567
log: nonnative.log
servers:
  -
    name: server_1
    class: Nonnative::TCPServer
    timeout: 1
    ports:
      - 12323
    log: server_1.log
  -
    name: server_2
    class: Nonnative::TCPServer
    timeout: 1
    ports:
      - 12324
    log: server_2.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

#### 🌐 HTTP

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

Set it up programmatically:

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
    s.ports = [4567]
    s.log = 'http_server_1.log'
  end
end
```

Set it up through configuration:

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
    ports:
      - 4567
    log: http_server_1.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

##### 🔀 HTTP Forward Proxy

The system allows you to define an in-process HTTP forward proxy server for external systems, e.g. `api.github.com`. This is a server implementation, not a fault-injection service proxy.

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

Set it up programmatically:

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
    s.ports = [4567]
    s.log = 'http_server_proxy.log'
  end
end
```

Set it up through configuration:

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
    ports:
      - 4567
    log: http_server_proxy.log
```

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

#### 📡 gRPC

Define your server:

Assume the gRPC service base class and response types below come from your generated gRPC stubs.

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

Set it up programmatically:

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
    s.ports = [9002]
    s.log = 'grpc_server_1.log'
  end
end
```

Set it up through configuration:

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
    ports:
      - 9002
    log: grpc_server_1.log
```

The `grpc` gem uses a global logger, so per-server gRPC log files are not independent. The first
initialized gRPC server sets the logger used by later gRPC servers in the same Ruby process.

Then load the file with:

```ruby
require 'nonnative'

Nonnative.configure do |config|
  config.load_file('configuration.yml')
end
```

### 🧩 Services

A service is an external dependency to your system that you **do not** want Nonnative to start (no OS process, no Ruby thread).

Services do not get process lifecycle management or TCP readiness/shutdown checks from Nonnative. They provide a named endpoint for a dependency that another tool already manages.

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

#### 🕸️ Proxies

These proxies can simulate different situations. Available proxy kinds are:

- `none` (this is the default)
- `fault_injection`

> [!WARNING]
> Unknown proxy kinds raise an error. If fault injection is not taking effect, check the `kind` spelling or register the custom kind before starting the system.

Custom proxy kinds can be registered through `Nonnative.proxies`:

```ruby
Nonnative.proxies['custom'] = CustomProxy
```

Only services support proxies. For `fault_injection`, keep the service `host`/`port` as the client-facing proxy endpoint and use nested `proxy.host`/`proxy.port` for the upstream target behind the proxy.

##### 🧩 Service Proxies

###### Programmatic Configuration

Add a proxy to a service configuration:

```ruby
config.service do |s|
  s.name = 'redis'
  s.host = '127.0.0.1'
  s.port = 16_379

  s.proxy = {
    kind: 'fault_injection',
    host: '127.0.0.1',
    port: 6379,
    log: 'proxy_server.log',
    wait: 1,
    options: {
      delay: 5
    }
  }
end
```

###### YAML Configuration

Add a proxy to a service YAML entry:

```yaml
services:
  -
    name: redis
    host: 127.0.0.1
    port: 16379
    proxy:
      kind: fault_injection
      host: 127.0.0.1
      port: 6379
      log: proxy_server.log
      wait: 1
      options:
        delay: 5
```

##### 🧪 Fault Injection

The `fault_injection` proxy allows you to simulate failures by injecting them. We currently support the following:

Clients connect to the service `host`/`port`, while the proxy forwards traffic to nested `proxy.host`/`proxy.port`.

- `close_all` - Closes the socket as soon as it connects.
- `delay` - Delays traffic on the connection. Defaults to 2 seconds and can be configured through options.
- `invalid_data` - Forwards client requests unchanged, then corrupts upstream responses before they reach the client.

###### 🧩 Fault Injection Services

Set the proxy state programmatically:

```ruby
name = 'name of service in configuration'
service = Nonnative.pool.service_by_name(name)

service.proxy.close_all # To use close_all.
service.proxy.reset # To reset it back to a good state.
```

Use the Cucumber proxy steps:

```cucumber
Given I set the proxy for service 'service_1' to 'close_all'
Then I should reset the proxy for service 'service_1'
```

### 🐹 Go

As we love using Go as a language for services we have added support to start binaries with defined parameters.

Programmatic Go binaries can be configured as normal argv process commands:

```ruby
Nonnative.configure do |config|
  config.process do |p|
    p.name = 'go'
    p.command = -> { Nonnative.go_argv(%w[cover], 'reports', 'your_binary', 'sub_command', '-i file:.config/server.yml') }
    p.ports = [12_345]
  end
end
```

Use `Nonnative.go_argv(...)` when a process should execute without shell interpretation, and `Nonnative.go_command(...)` when a caller needs a command string for Ruby's shell-style `spawn` behavior.

YAML `go:` configuration is for Go test binaries compiled with `go test -c`. It builds argv entries in this order: executable, optional `-test.*` profiling/trace/coverage flags, command, then parameters. Parameter strings are parsed into argv words with shell-style quoting, but the argv entries are executed without shell interpretation.

> [!IMPORTANT]
> If `tools` is omitted or empty, Nonnative enables all Go tools: `prof`, `trace`, and `cover`. Provide a subset, such as `tools: [cover]`, to limit the generated `-test.*` flags.

To get this to work you will need to create a `main_test.go` file with these contents:

```go
//go:build features
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

Set it up through configuration:

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
        - "-i file:.config/server.yml"
    timeout: 5
    ports:
      - 8000
    log: go.log
```
