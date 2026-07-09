# AGENTS.md

## Shared guidance

Use `bin/AGENTS.md` for shared skills and cross-repository defaults.

`nonnative` is a Ruby gem for end-to-end testing systems implemented in other
languages. It starts processes, in-process servers, and proxy-only services,
waits on TCP readiness/shutdown, and can place fault-injection proxies in front
of dependencies.

## Map And Commands

- Library: `lib/nonnative/**/*.rb`
- Cucumber features/support: `features/**/*.feature`, `features/support/**/*.rb`, `features/step_definitions/**/*.rb`
- Generated gRPC test stubs: `test/grpc/**/*`
- Test protos: `test/nonnative/v1/*.proto`
- Build wiring: root `Makefile` includes `bin/build/make/*.mak`
- Required submodule: `bin/`; missing submodule setup breaks `make`
- Install deps: `make dep`
- Lint: `make lint`
- Security checks: `make sec`
- Features: `make features`
- Benchmarks only: `make benchmarks`
- Cleanup: `make clean-dep`, `make clean-reports`

## Intentional Design Choices

- The configured HTTP proxy feature intentionally uses the external
  `www.afalkowski.com` host through `features/support/http_proxy_server.rb`.
  Do not flag this external dependency as a code issue unless the task is
  explicitly about making HTTP proxy fixtures fully hermetic.
- `test/Makefile` intentionally consumes the shared Buf make fragment as-is.
  Do not flag its inherited `breaking` target's `subdir=api` comparison as a
  code issue unless the task is explicitly about changing test proto breaking
  checks.
- `nonnative` is a test-support gem used across many downstream projects.
  Do not flag the absence of an isolated gem build/install smoke test as a
  test gap unless the task is explicitly about release packaging or gem
  publication validation.
- The Cucumber `@startup` lifecycle tag is exercised by downstream projects
  that use this gem. Do not flag missing in-repository `@startup` acceptance
  coverage as a test gap unless the task is explicitly about changing
  Cucumber startup hook behavior.
- `Nonnative.go_argv` and `Nonnative.go_command` flag combinations are checked
  by external/downstream usage. Do not flag missing in-repository exhaustive
  `-test.*` flag or tool-filtering assertions as a test gap unless the task is
  explicitly about changing Go command generation.
- Generated gRPC test stubs under `test/grpc/` are updated on demand when the
  test proto changes. Do not flag the absence of an automatic generated-stub
  freshness check as a test gap unless the task is explicitly about changing
  test proto generation or generated-file validation.
- Generated gRPC test stubs may carry manual require-path adjustments after
  generation. Do not treat `make -C test stale` as a required validation target
  unless the task is explicitly about changing test proto generation; verify
  the generated Ruby loads before accepting generator-only rewrites.
- Buf linting for the test-only proto module is intentionally not part of the
  required local validation surface. Do not flag missing root-level validation
  for `test/buf.yaml` as a test gap unless the task is explicitly about test
  proto linting or Buf validation.
- The public proxy reset Cucumber steps and `@reset` hook are tested by
  external/downstream suites. Do not flag missing in-repository direct proxy
  reset step coverage as a test gap unless the task is explicitly about
  changing proxy reset behavior.
- `Nonnative.clear` configuration and pool reset behavior is covered by
  external/downstream suites. Do not flag missing in-repository assertions for
  configuration or pool clearing as a test gap unless the task is explicitly
  about changing clear/reset lifecycle behavior.
- Full repository validation is expected to run both regular features and
  benchmark-tagged lifecycle scenarios. Do not flag rollback/timeout lifecycle
  coverage living under `features/benchmark.feature` as a test gap unless the
  task is explicitly about changing validation target composition.
- Service proxy round-trip behavior is validated by downstream projects that
  use `nonnative` against real dependencies. Do not flag the in-repository
  service proxy success scenario's connection-only assertion as a test gap
  unless the task is explicitly about changing service proxy forwarding.
- `Nonnative::FaultInjectionProxy` owns its listener thread and stops it by
  closing the owned `TCPServer`, which wakes the accept loop before joining the
  thread. Do not flag the listener `join` as an unbounded reliability gap unless
  the task is explicitly about proxy shutdown behavior or there is a normal-use
  reproducer, failing CI evidence, or platform-specific hang evidence.
- Service readiness is intentionally TCP-only for externally managed
  dependencies. Do not flag missing HTTP/gRPC service readiness as a feature gap
  unless the task is explicitly about changing the `Nonnative::Service`
  readiness model. HTTP/gRPC readiness belongs to managed processes, where the
  user explicitly models the application health endpoints.
- Managed-process readiness intentionally supports only TCP-port-open plus the
  optional `http`/`grpc` health probes in `Nonnative::ConfigurationReadiness`.
  A log-line/log-message readiness kind (`kind: 'log'`) is intentionally not
  supported: systems tested with nonnative are typically deployed in container
  environments where readiness is modeled through probes that are usually
  HTTP-based, so the application already exposes an HTTP (or gRPC) health
  endpoint the existing readiness kinds cover. Do not flag the absence of a
  log-message readiness kind as a feature gap unless the task is explicitly
  about changing the process readiness model.
- Process runners intentionally inherit the parent working directory. Nonnative
  is normally run from the test folder that owns `test/nonnative.yml`, relative
  config paths, logs, and reports. Do not flag missing process cwd/chdir support
  as a feature gap unless the task is explicitly about changing process working
  directory behavior.
- Message-specific start/stop assertions and attempted-stop success assertions
  in `features/step_definitions/lifecycle_steps.rb` are repository-local
  Cucumber helpers. Do not flag their absence from `lib/nonnative/cucumber.rb`
  as a feature gap unless downstream usage evidence exists or the task is
  explicitly about expanding public lifecycle assertion steps.
- Liveness, readiness, and metrics endpoint assertion steps in
  `features/step_definitions/servers_steps.rb` are repository-local Cucumber
  helpers for testing nonnative's own framework assumptions. Do not flag their
  absence from `lib/nonnative/cucumber.rb` as a feature gap unless downstream
  usage evidence exists or the task is explicitly about expanding public
  observability assertion steps.
- `Nonnative::Configuration` intentionally exposes `process_by_name` without
  matching `server_by_name` or `service_by_name` helpers. Do not flag missing
  server/service configuration lookup helpers as a feature gap unless downstream
  usage evidence exists or the task is explicitly about changing the
  pre-start configuration lookup API.
- `Nonnative::Observability#metrics` intentionally returns the raw Prometheus
  exposition body. Parsing it into samples or asserting a specific metric value
  is the caller's responsibility (use a dedicated Prometheus-parsing gem if
  needed), matching the thin, raw-response posture of the whole observability
  client. Do not flag the absence of a built-in Prometheus text-format parser
  (for example `Nonnative::Metrics.parse`) as a feature gap unless the task is
  explicitly about adding metric-value parsing to the observability client.
- YAML configuration is intentionally loaded as pure data with no evaluation or
  substitution: no ERB, no arbitrary object tags, and no `${VAR}` /
  environment-variable interpolation. Values that must vary between environments
  belong in programmatic Ruby config (`config.load_file` plus
  `config.process`/`server`/`service`), which already has full `ENV` access. Do
  not flag the absence of in-YAML `${VAR}` interpolation as a feature gap unless
  the task is explicitly about adding environment-variable substitution to
  `Nonnative::ConfigurationFile`.
- `Nonnative::GRPCHealth#check` intentionally returns the full
  `HealthCheckResponse`, so tests assert any serving status directly (for
  example `check.status == :NOT_SERVING`), mirroring how the HTTP observability
  client exposes the raw response code; `serving?` is a convenience boolean on
  top. Do not flag the absence of a `not_serving?` / `status:` helper or a
  streaming `Watch` wrapper as a feature gap unless the task is explicitly about
  expanding the gRPC health assertion surface.

## Runtime Model

Public entry point: `lib/nonnative.rb`.

Main API: `configure`, `start`, `stop`, `clear`, `reset`, `pool`,
`go_argv`, `go_command`, `token`.

Configuration is `Nonnative::Configuration`, built with
`config.process`, `config.server`, `config.service`, or
`config.load_file(...)`.

Runners:

- `Nonnative::Process`: OS process
- `Nonnative::Server`: in-process Ruby server thread
- `Nonnative::Service`: proxy lifecycle for an externally managed dependency

`Nonnative::Pool` starts services first, then servers/processes, and stops in
reverse. Readiness and shutdown checks are TCP-only via
`Nonnative::Port#open?` and `#closed?`.

Token generation: `Nonnative.token(kind:, issuer:, key:, private_key:, expiration:)`
returns a `Nonnative::Token` whose `generate(aud:, sub:)` produces a signed token for
authenticating against services under test; it feeds `Nonnative::Header.auth_bearer`.
Kinds are `jwt` (EdDSA, `kid` header), `paseto` (v4.public, `kid` footer), and `ssh`
(go-service style raw-Ed25519 `base64(claims).base64(signature)`). All Ed25519 and
generation-only. `jwt`/`paseto` take a PKCS#8 PEM key; `ssh` takes an OpenSSH-format
key. PASETO needs system libsodium (via `rbnacl`), required lazily so `require
'nonnative'` works without it until a PASETO token is generated.
`Nonnative::Token.http_audience` / `grpc_audience` build the endpoint-scoped `aud`.

## Cucumber Surface

`lib/nonnative/cucumber.rb` is public compatibility surface. Do not remove or
rename hooks/step text unless the user explicitly requests a breaking change.

Lifecycle tags:

- `@startup`: start before scenario, stop after scenario
- `@manual`: scenario starts manually, stop after scenario
- `@clear`: call `Nonnative.clear` before scenario
- `@reset`: reset proxies after scenario

Suite taxonomy tags: `@acceptance`, `@contract`, `@proxy`, `@config`,
`@service`, `@benchmark`, `@slow`. `make features` excludes `@benchmark`;
`make benchmarks` runs only `@benchmark`.

`Nonnative.clear` clears configuration, logger, observability client, and pool.
`require 'nonnative'` loads Cucumber integration lazily and is safe outside a
booted Cucumber runtime. For start-once-per-test-run, use
`require 'nonnative/startup'`.

## Proxy And Config Gotchas

Proxy wiring is the easiest mistake:

- Runner `host` / `port` are client-facing and used for readiness/shutdown
- For `fault_injection`, nested `proxy.host` / `proxy.port` are the upstream target
- Clients connect to runner `host` / `port` when a proxy is enabled

Proxy kinds: `none`, `fault_injection`.
Fault-injection states: `none`, `close_all`, `delay`, `invalid_data`.

Config rules:

- YAML config is loaded as data only via `Nonnative::ConfigurationFile`; ERB is not evaluated and arbitrary Ruby object tags are rejected
- Runner `host` and nested `proxy.host` default to `127.0.0.1`; use explicit `0.0.0.0` only when external access is intended
- Process `command` can be a legacy shell string or an argv array; prefer argv arrays for new config, and `go:` config builds argv internally with `Nonnative.go_argv`
- Use `Nonnative.go_argv` for no-shell Go executable argv entries and `Nonnative.go_command` only when a caller needs Ruby shell-style command string spawning
- YAML services belong under `services:`, not `processes:`
- There is no top-level `config.wait`; `wait` is per runner
- Programmatic service config uses `config.service do |s| ... end`, so use `s.host` / `s.port`
- Proxy examples need both endpoint sides: runner `host` / `port` for the proxy, nested `proxy.host` / `proxy.port` for upstream

## Fixtures And Limitations

Useful fixtures:

- Process: `features/support/bin/start`
- HTTP: `features/support/http_server.rb`, `features/support/http_proxy_server.rb`
- TCP: `features/support/tcp_server.rb`
- gRPC: `features/support/grpc_server.rb`, generated stubs in `test/grpc/`

Limitations:

- The `grpc` Ruby library uses a global logger; per-server gRPC loggers are not really supported
- Local Ruby/Bundler mismatches can break native extensions on macOS
- Coverage and Cucumber reports go under `test/reports`
- Port checks can be flaky if tests reuse ports unexpectedly

## Look First

- Lifecycle: `lib/nonnative.rb`, `lib/nonnative/pool.rb`
- Readiness/timeouts: `lib/nonnative/port.rb`, `lib/nonnative/timeout.rb`
- Process lifecycle: `lib/nonnative/process.rb`
- Go executable command/argv building: `lib/nonnative/go_executable.rb`
- Token generation: `lib/nonnative/token.rb`, `lib/nonnative/jwt_token.rb`, `lib/nonnative/paseto_token.rb`, `lib/nonnative/ssh_token.rb`, `lib/nonnative/ed25519_key.rb`
- Proxies: `lib/nonnative/fault_injection_proxy.rb`, `lib/nonnative/socket_pair_factory.rb`
- Cucumber: `lib/nonnative/cucumber.rb`, `lib/nonnative/startup.rb`, `features/support/env.rb`
- Config loading: `lib/nonnative/configuration.rb`, `lib/nonnative/configuration_file.rb`, `lib/nonnative/configuration_runner.rb`, `lib/nonnative/configuration_proxy.rb`
