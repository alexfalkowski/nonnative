# AGENTS.md

This repo is the `nonnative` Ruby gem: a Ruby-first harness for end-to-end testing of systems implemented in other languages by starting processes/servers/services, waiting on TCP port readiness, and optionally putting fault-injection proxies in front of them.

## Quick map

- Library code: `lib/nonnative/**/*.rb`
- Acceptance tests: `features/**/*.feature`, `features/support/**/*.rb`, `features/step_definitions/**/*.rb`
- Generated gRPC Ruby stubs for tests: `test/grpc/**/*`
- Test proto files: `test/nonnative/v1/*.proto`
- Build wiring: root `Makefile` includes `bin/build/make/*.mak`

## Key repo dependency

This repo depends on the `bin/` git submodule.

- `.gitmodules` points to `git@github.com:alexfalkowski/bin.git`
- CI runs `git submodule sync && git submodule update --init`
- If `bin/` is missing or you do not have SSH access, `make` targets will fail

## Core commands

- Install deps: `make dep`
- Lint: `make lint`
- Run features: `make features`
- Run benchmarks only: `make benchmarks`
- Clean deps: `make clean-dep`
- Clean reports: `make clean-reports`

## Runtime model

Public entry point is `lib/nonnative.rb`.

Main module API:

- `configure`
- `start`
- `stop`
- `clear`
- `reset`
- `pool`

Configuration lives in `Nonnative::Configuration` and is built either:

- programmatically with `config.process`, `config.server`, `config.service`
- from YAML with `config.load_file(...)`

Runtime runners:

- `Nonnative::Process`: manages an OS process
- `Nonnative::Server`: manages an in-process Ruby server thread
- `Nonnative::Service`: manages only proxy lifecycle for an externally managed dependency

`Nonnative::Pool` starts services first, then servers/processes, and stops in the reverse direction.

Readiness and shutdown checks are TCP-only via `Nonnative::Port#open?` and `#closed?`.

## Cucumber integration

Cucumber integration lives in `lib/nonnative/cucumber.rb`.

Treat `lib/nonnative/cucumber.rb` as a public compatibility surface for library consumers.
Existing hooks and step text should not be removed or renamed unless the user explicitly wants a breaking change.

Supported tags:

- `@startup`: start before scenario, stop after scenario
- `@manual`: scenario starts manually, stop after scenario
- `@clear`: call `Nonnative.clear` before scenario
- `@reset`: reset proxies after scenario

Repo-owned feature files also use suite taxonomy tags:

- `@acceptance`: end-to-end runner and client flows
- `@contract`: lower-level lifecycle / command coverage
- `@proxy`: proxy-specific coverage
- `@config`: scenarios or example sets that load YAML/configuration
- `@service`: coverage centered on external services
- `@benchmark`: benchmark-only scenarios
- `@slow`: slower-running scenarios, currently benchmarks

`make features` excludes `@benchmark`; `make benchmarks` runs only `@benchmark`.

`Nonnative.clear` now clears:

- configuration
- logger
- observability client
- pool

`require 'nonnative'` still loads the Cucumber integration, but hook/step registration is lazy, so plain `require 'nonnative'` is safe outside a booted Cucumber runtime.

For “start once per test run”, use `require 'nonnative/startup'`.

## Proxy wiring

This is the easiest thing to get wrong.

- Runner `host` / `port` are the client-facing endpoint and the values used by readiness/shutdown checks
- For `fault_injection`, nested `proxy.host` / `proxy.port` are the upstream target behind the proxy
- Clients should connect to the runner `host` / `port` when a proxy is enabled

Available proxy kinds:

- `none`
- `fault_injection`

Fault injection states:

- `none`
- `close_all`
- `delay`
- `invalid_data`

## Config gotchas

- Services must be declared under `services:` in YAML, not `processes:`
- There is no top-level `config.wait`; `wait` is per runner
- Service configs use `config.service do |s| ... end`, so use `s.host` / `s.port`
- Proxy examples need both sides of the split:
  - runner `host` / `port` = proxy endpoint
  - nested `proxy.host` / `proxy.port` = upstream target

## Test fixtures worth knowing

- Local process fixture: `features/support/bin/start`
- HTTP fixtures: `features/support/http_server.rb`, `features/support/http_proxy_server.rb`
- TCP fixture: `features/support/tcp_server.rb`
- gRPC fixtures: `features/support/grpc_server.rb`, plus generated stubs under `test/grpc/`

## Important limitations / gotchas

- Ruby version is constrained by `nonnative.gemspec` to `>= 4.0.0` and `< 5.0.0`
- The `grpc` Ruby library uses a global logger; per-server gRPC loggers are not really supported
- `make` depends on the `bin/` submodule being present
- Local Ruby/Bundler mismatches can break native extensions on macOS
- Coverage output and Cucumber reports are written under `test/reports`
- Port checks can be flaky if tests reuse ports unexpectedly

## Where to look first

- Lifecycle orchestration: `lib/nonnative.rb`, `lib/nonnative/pool.rb`
- Readiness / timeouts: `lib/nonnative/port.rb`, `lib/nonnative/timeout.rb`
- Process lifecycle: `lib/nonnative/process.rb`
- Proxies / fault injection: `lib/nonnative/fault_injection_proxy.rb`, `lib/nonnative/socket_pair_factory.rb`
- Cucumber integration: `lib/nonnative/cucumber.rb`, `lib/nonnative/startup.rb`, `features/support/env.rb`
- Config loading: `lib/nonnative/configuration.rb`, `lib/nonnative/configuration_runner.rb`, `lib/nonnative/configuration_proxy.rb`
