# AGENTS.md

## Shared skills

This repository uses the shared skills from `bin/skills/`. Read
`bin/AGENTS.md` for the canonical shared skill list and use the smallest
matching skill for the task.

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
- Required submodule: `bin/` from `git@github.com:alexfalkowski/bin.git`; missing SSH/submodule setup breaks `make`
- Install deps: `make dep`
- Lint: `make lint`
- Features: `make features`
- Benchmarks only: `make benchmarks`
- Cleanup: `make clean-dep`, `make clean-reports`

## Runtime Model

Public entry point: `lib/nonnative.rb`.

Main API: `configure`, `start`, `stop`, `clear`, `reset`, `pool`.

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
- Proxies: `lib/nonnative/fault_injection_proxy.rb`, `lib/nonnative/socket_pair_factory.rb`
- Cucumber: `lib/nonnative/cucumber.rb`, `lib/nonnative/startup.rb`, `features/support/env.rb`
- Config loading: `lib/nonnative/configuration.rb`, `lib/nonnative/configuration_file.rb`, `lib/nonnative/configuration_runner.rb`, `lib/nonnative/configuration_proxy.rb`
