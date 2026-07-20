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
- wait for readiness/shutdown using **TCP port checks**, optional process HTTP/gRPC checks, and optional service TCP checks.

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
> Treat YAML configuration as plain data. ERB is not evaluated, `${VAR}` values are not expanded,
> and arbitrary Ruby object tags are rejected. Unknown structural keys may be ignored, although YAML
> syntax, object safety, and supported value shapes are still validated. Keep values that vary by
> environment in programmatic Ruby configuration, where Ruby's `ENV` is available.

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
- `timeout`: max time (seconds) for each readiness/shutdown check. For processes, the same value also
  bounds optional HTTP/gRPC probes and graceful child exit after the stop signal. Defaults to `1.0`.
  A value of `0` fails immediately; setting it to `nil` programmatically does the same.
- `wait`: small sleep (seconds) between lifecycle steps.
- `log`: per-runner log file used by process output redirection or server implementations.

Process-only fields:
- `readiness`: optional list of startup readiness checks. Supported kinds are `http` and `grpc`.
  HTTP checks require explicit `port` and path-only `path`. gRPC checks require explicit `port` and
  health `service`.

Service fields:
- `port`: client-facing service port.
- `timeout`: max time (seconds) for opt-in service readiness checks. Defaults to `1.0`. A value of
  `0` fails immediately; setting it to `nil` programmatically does the same.
- `readiness`: optional list of startup readiness checks. Supported kind is `tcp`, which requires
  explicit `host` and `port`.

Nonnative readiness and shutdown checks are TCP port checks by default. Configure process/server ports that are dedicated to the test run; if another process is already listening on the same endpoint, results are undefined. Processes can also opt into HTTP and gRPC readiness checks that run after TCP readiness succeeds. HTTP readiness sends a plain HTTP `GET` without configurable request headers and is ready only when the final response is 2xx. gRPC readiness uses the standard health `Check` over an insecure channel and is ready only for `SERVING`. Non-ready responses are retried until the process timeout elapses. Services do not get automatic TCP readiness/shutdown checks, but can opt into TCP startup readiness for externally managed dependencies. HTTP readiness paths must be path-only values, such as `/test/readyz`; absolute URLs and scheme-relative URLs are rejected.

> [!WARNING]
> TCP readiness and shutdown checks only prove that a TCP port opened or closed. HTTP and gRPC readiness are process-only. Service readiness is TCP-only and should target the dependency endpoint that must be reachable before managed servers/processes start.

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

`Nonnative.start` runs ordered tiers: service lifecycle calls and optional readiness checks complete,
then server lifecycle and readiness checks complete, then process lifecycle and readiness checks run.
A failed service lifecycle call or readiness check prevents later tiers; other collected startup errors
trigger rollback after the attempted tiers finish. `Nonnative.stop` reverses the tiers: processes, servers, then
services. Model dependencies in that direction; a managed server can satisfy a process dependency,
but a server cannot wait on a managed process. Startup failures raise `Nonnative::StartError`, and
shutdown failures raise `Nonnative::StopError`.

> [!WARNING]
> `Nonnative.clear` forgets the current pool; it does not stop live processes, server threads, or
> proxies. To reuse the same Ruby process, call `Nonnative.stop`, then `Nonnative.clear`, configure
> the next system, and call `Nonnative.start`. `clear` also clears the memoized configuration,
> logger, and observability client.

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

HTTP error statuses are returned as response objects so callers can inspect `.code` and `.body`.
Request timeouts and broken connections raise their RestClient exceptions; observability requests are
not retried automatically.

`Nonnative.grpc_health` is a helper for the standard gRPC health checking protocol:

```ruby
health = Nonnative.grpc_health(
  host: '127.0.0.1',
  port: 12_322,
  service: 'example.v1.ExampleService',
  timeout: 2
)

expect(health.serving?).to eq(true)
```

The helper always uses an insecure plaintext gRPC channel. Pass `service: ''` or `nil` to check the
overall server. `check` returns the full `HealthCheckResponse` and propagates gRPC failures, while
`serving?` returns `false` for any non-`SERVING` status or gRPC failure.

### 🔑 Tokens

`Nonnative.token` builds a signer for authenticating requests against a service under test. You pass the signing parameters directly (parsed from your own configuration); it is not coupled to any service's config format. The generated string is ready for `Nonnative::Header.auth_bearer`.

```ruby
token = Nonnative.token(
  kind: 'jwt',
  issuer: 'iss',
  key: 'key-1',
  private_key: 'config/ed25519.pem',
  expiration: 3600
)

headers = Nonnative::Header.auth_bearer(
  token.generate(aud: Nonnative::Token.http_audience('GET', '/v1/things'), sub: 'user-1')
)
```

Supported `kind` values (all Ed25519, generation only):

- `jwt`: EdDSA JWT with the key id in the `kid` header. `private_key` is a PKCS#8 PEM file.
- `paseto`: PASETO v4.public with the key id in a `{"kid":"..."}` footer. `private_key` is a PKCS#8 PEM file. Requires system **libsodium** (via `rbnacl`); it loads lazily, so `require 'nonnative'` works without libsodium until you generate a PASETO token.
- `ssh`: go-service style `base64(claims).base64(signature)` with a raw Ed25519 signature over `v1` claims. `private_key` is an **OpenSSH-format** key. `issuer` and `sub` are ignored (the subject is the key id).

The audience is endpoint-scoped; build it with the helpers:

```ruby
Nonnative::Token.http_audience('GET', '/v1/things')        # => "GET /v1/things"
Nonnative::Token.grpc_audience('/health.v1.Health/Check')  # => "/health.v1.Health/Check"
```

By default the time claims are pinned to the current time (`iat`/`nbf` at now, `exp` at `now + expiration`). To write negative auth tests, `generate` accepts optional absolute `Time` overrides — `issued_at`, `not_before`, and `expires_at` — for minting not-yet-valid or clock-skewed tokens:

```ruby
# a token that is not valid until an hour from now
token.generate(aud: 'GET /v1/things', sub: 'user-1', not_before: Time.now + 3600)
```

`ssh` tokens have no `nbf` claim, so passing `not_before` for the `ssh` kind raises `ArgumentError`.

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

#### 🥒 Public Cucumber steps

The shipped steps are compatibility surface for downstream suites:

- `When I start the system` starts immediately. For expected failures, pair
  `When I attempt to start the system` with `Then starting the system should raise an error`, or use
  the equivalent stop steps.
- `Then I should see {string} as healthy` expects the configured health endpoint to return `200` and
  a body containing neither the supplied service name nor `service unavailable`; `unhealthy` expects
  `503` and a body identifying the service or `service unavailable`.
- `Then the process {string} should consume less than {string} of memory` accepts values such as
  `25mb` for a started process.
- The two log steps search either a configured process log or an explicit file path for the requested
  text: `Then I should see a log entry of {string} for process {string}` and
  `Then I should see a log entry of {string} in the file {string}`.
- `Given I set the proxy for service {string} to {string}` accepts `close_all`, `reset_peer`, `delay`,
  `timeout`, `invalid_data`, `bandwidth`, `limit_data`, `slicer`, `flaky`, or `reset`; the reset action
  step is `Then I should reset the proxy for service {string}`.

```cucumber
@manual
Scenario: startup is expected to fail
  When I attempt to start the system
  Then starting the system should raise an error
```

### ⚙️ Processes

A process is some sort of command that you would run locally.
Programmatic `p.command` values must be callables that return a shell string or an argv array. YAML `command` values can be scalars or lists and are wrapped internally. String commands preserve legacy shell semantics, while argv arrays avoid shell interpretation and are preferred for new configuration.

> [!TIP]
> Prefer argv arrays for new process commands. Use shell strings only when you intentionally need shell parsing, expansion, or redirection.

Managed processes inherit the Ruby parent's working directory and environment; loading YAML from a
different directory does not change the child working directory. Relative command, config, log, and
generated-output paths resolve from that inherited directory. Configured `environment` values are
stringified and override variables with the same names while preserving the rest of the parent
environment.

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
    p.readiness = [
      { kind: 'http', port: 12_321, path: '/test/readyz' },
      { kind: 'grpc', port: 12_322, service: 'example.v1.ExampleService' }
    ]
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
      - kind: http
        port: 12321
        path: /test/readyz
      - kind: grpc
        port: 12322
        service: example.v1.ExampleService
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

On stop, Nonnative sends the configured signal (`INT` by default) and waits up to `timeout` for the
child to exit. If it remains alive, Nonnative sends `KILL` and reports the stop as unsuccessful, so
`Nonnative.stop` raises `Nonnative::StopError` even if the configured shutdown ports close.

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
    class HelloService < Nonnative::HTTPService
      get '/hello' do
        'Hello World!'
      end
    end

    class HTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super(HelloService.new, service)
      end
    end
  end
end
```

To run multiple Rack services on one managed port, pass a non-empty `Rack::URLMap` mount map. Keys
can be path prefixes beginning with `/` or host-qualified URLs; the mounted application receives the
remaining `PATH_INFO`:

```ruby
module Nonnative
  module Features
    class HealthService < Nonnative::HTTPService
      get '/' do
        'ok'
      end
    end

    class HTTPServer < Nonnative::HTTPServer
      def initialize(service)
        super({ '/api' => HelloService.new, '/health' => HealthService.new }, service)
      end
    end
  end
end
```

The existing single-service form remains supported. Nonnative converts a mount map to a
`Rack::URLMap` and keeps one server lifecycle and port. An empty mount map raises `ArgumentError`.

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

The upstream scheme defaults to HTTPS on the scheme's default port; pass `scheme:`/`port:` to
`Nonnative::HTTPProxyServer.new` to target an `http://` upstream or a non-default port. The proxy
forwards the request path and query for `GET`, `HEAD`, `POST`, `PUT`, `PATCH`, `DELETE`, and
`OPTIONS`, while removing proxy credentials, `Host`, `Accept-Encoding`, hop-by-hop headers, and
headers nominated by `Connection` before the upstream request.

The proxy preserves the upstream status, body, and safe end-to-end response headers such as `Content-Type`, `ETag`, and application-specific metadata. It removes hop-by-hop, connection-nominated, proxy-authentication, and framing headers; `Set-Cookie`, `Location`, and `Content-Encoding` are not forwarded.

When the upstream is unavailable, disconnects unexpectedly, or times out, the proxy returns a clean gateway response (`502` or `504`) instead of exposing an internal exception page.

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

Assume the gRPC service type and response types below come from your generated gRPC stubs.

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

To serve multiple gRPC services on one managed port, pass a non-empty array of handler classes or
instances:

```ruby
module Nonnative
  module Features
    class HealthService < Grpc::Health::V1::Health::Service
      def check(_request, _call)
        Grpc::Health::V1::HealthCheckResponse.new(status: :SERVING)
      end
    end

    class GRPCServer < Nonnative::GRPCServer
      def initialize(service)
        super([Greeter.new, HealthService.new], service)
      end
    end
  end
end
```

The existing single-handler form remains supported. Nonnative registers each handler before the
server starts, so application and standard health handlers can share one lifecycle and endpoint.

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

Services do not get process lifecycle management or automatic TCP readiness/shutdown checks from Nonnative. They provide a named endpoint for a dependency that another tool already manages, and can opt into TCP startup readiness when the dependency must be reachable before managed servers/processes start.

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
    s.timeout = 5
    s.readiness = [{ kind: 'tcp', host: '127.0.0.1', port: 5432 }]
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
    timeout: 5
    readiness:
      - kind: tcp
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
class CustomProxy < Nonnative::Proxy
  # Inherit #initialize(service), or call super from a custom initializer.
  def start; end
  def stop; end
  def reset; end
end

Nonnative.proxies['custom'] = CustomProxy

Nonnative.configure do |config|
  config.service do |s|
    s.name = 'dependency'
    s.host = '127.0.0.1'
    s.port = 12_345
    s.proxy.kind = 'custom'
  end
end
```

Custom proxies must accept the service configuration and implement `start`, `stop`, and `reset`;
Nonnative invokes those methods during service lifecycle and pool reset.

Only services support proxies. For `fault_injection`, keep the service `host`/`port` as the client-facing proxy endpoint and use nested `proxy.host`/`proxy.port` for the upstream target behind the proxy.
When service readiness is configured for a proxied dependency, set the readiness `host`/`port` to the upstream dependency, not the client-facing proxy listener.

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

  s.readiness = [{ kind: 'tcp', host: '127.0.0.1', port: 6379 }]
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
    readiness:
      - kind: tcp
        host: 127.0.0.1
        port: 6379
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
- `reset_peer` - Resets the socket as soon as it connects, so clients observe a TCP reset (`Errno::ECONNRESET`) rather than the graceful close performed by `close_all`.
- `delay` - Delays traffic on the connection. Defaults to 2 seconds and can be configured through `options.delay`. An optional `options.jitter` (seconds) adds a random offset in `-jitter..jitter` to each delay (a negative value uses its magnitude), so clients see variable, tail-latency-like timing instead of a flat value.
- `timeout` - Accepts the connection and stalls traffic until reset or stop closes the connection, so clients exercise their own read timeout behavior.
- `invalid_data` - Forwards client requests unchanged, then corrupts upstream responses before they reach the client.
- `bandwidth` - Throttles forwarded throughput to `options.rate` kilobytes per second (1 KB = 1024 bytes) by sleeping in proportion to the bytes read, in both directions, so clients see a slow-but-alive dependency. When `rate` is absent or not positive, traffic forwards at full speed.
- `limit_data` - Forwards client requests unchanged, then sends the first `options.bytes` bytes of the upstream byte stream on each connection and gracefully closes the connection. When `bytes` is absent or not positive, traffic forwards at full speed.
- `slicer` - Forwards client requests unchanged, then writes each response to the client in `options.slice_size`-byte pieces, optionally separated by `options.slice_delay` seconds, so a client must perform multiple reads to reassemble the message. When `slice_size` is absent or not positive, traffic forwards at full speed.
- `flaky` - Fails a fraction of new connections (closed immediately, like `close_all`) controlled by `options.probability` (0.0-1.0), forwarding the rest normally, so a client's retry/reconnect logic sees both failures and successes while this state stays active. When `probability` is absent or not positive, traffic forwards at full speed.

###### 🧩 Fault Injection Services

> [!WARNING]
> Every proxy state change closes active client connections so that new connections observe the new
> state. Apply the state before connecting, and reconnect after changing or resetting it.

Set the proxy state programmatically:

```ruby
name = 'name of service in configuration'
service = Nonnative.pool.service_by_name(name)

service.proxy.close_all # To use close_all.
service.proxy.reset_peer # To reset (RST) client connections.
service.proxy.timeout # To stall traffic until reset or stop.
service.proxy.limit_data # To truncate the upstream byte stream at options.bytes.
service.proxy.reset # To reset it back to a good state.
```

Use the Cucumber proxy steps:

```cucumber
Given I set the proxy for service 'service_1' to 'close_all'
Given I set the proxy for service 'service_1' to 'reset_peer'
Given I set the proxy for service 'service_1' to 'timeout'
Given I set the proxy for service 'service_1' to 'limit_data'
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

Create the configured `output` directory before starting Nonnative; the helper does not create it and
the Go test binary must be able to write there. Artifact names include the executable basename
without its extension, the command, and a random four-character suffix, for example
`reports/your_binary-sub_command-Ab12-cpu.prof`.

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
