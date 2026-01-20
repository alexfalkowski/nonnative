# AGENTS.md

This repository is the **`nonnative` Ruby gem**. It provides a Ruby-first harness for end-to-end testing of services implemented in other languages by **starting processes/servers/services**, waiting for readiness (port checks), and optionally running **fault-injection proxies**.

Everything below is based on the files currently in this repo (no assumptions).

## Quick orientation

- **Library code**: `lib/nonnative/**/*.rb`
- **Acceptance tests**: `features/**/*.feature` + `features/support/**/*.rb` + `features/step_definitions/**/*.rb` (Cucumber)
- **Generated gRPC Ruby stubs for tests**: `test/grpc/**/*` (excluded from RuboCop)
- **Proto definitions for test fixtures**: `test/nonnative/v1/*.proto`
- **Build system**: `Makefile` includes make fragments from the `bin/` submodule (`bin/build/make/*.mak`).

## Important repo dependency: `bin/` submodule

This repo uses a git submodule at `bin/`:

- `.gitmodules` points to `git@github.com:alexfalkowski/bin.git`.
- CI runs `git submodule sync && git submodule update --init` before running `make` targets (`.circleci/config.yml`).

If you don’t have SSH access to that repo, `make` targets that include `bin/build/make/*.mak` will fail.

### Submodule commands

```sh
git submodule sync
git submodule update --init
```

## Essential commands (from Makefiles)

### Ruby version

- `nonnative.gemspec` requires Ruby `>= 3.4.0` and `< 4.0.0`.

### Install deps

Ruby deps are managed by Bundler and installed into `vendor/bundle`:

```sh
make dep
```

Implementation lives in `bin/build/make/ruby.mak` (included by root `Makefile`).

### Lint

```sh
make lint
```

Runs RuboCop:

- `bundler exec rubocop` (`bin/build/make/ruby.mak:4-5`)
- Config: `.rubocop.yml` (TargetRubyVersion 3.4; max line length 150)

Auto-fix:

```sh
make fix-lint
# or
make format
```

### Run acceptance tests (Cucumber)

```sh
make features
```

This calls `bin/quality/ruby/feature`, which runs:

- `bundler exec cucumber --profile report ... --tags "not @benchmark" ...`
- Cucumber profile `report` is defined in `.config/cucumber.yml` and writes:
  - JUnit XML to `test/reports`
  - HTML report to `test/reports/index.html`

Run only benchmarks:

```sh
make benchmarks
```

### Coverage

Cucumber loads SimpleCov via `features/support/env.rb` and writes coverage output under `test/reports/`.

Codecov config exists in `.codecov.yml` and CI uploads coverage in `.circleci/config.yml`.

Local upload target:

```sh
make codecov-upload
```

### Clean deps / reports

```sh
make clean-dep
make clean-reports
```

## Testing patterns and hooks

### Cucumber hooks and tags

Cucumber integration lives in `lib/nonnative/cucumber.rb`:

- `@startup`: starts and stops Nonnative around each scenario.
- `@manual`: only stops after scenario.
- `@clear`: calls `Nonnative.clear` before scenario.
- `@reset`: resets proxies after scenario.

The “start once per test run” strategy is implemented by requiring `nonnative/startup`:

- `lib/nonnative/startup.rb` calls `Nonnative.start` and registers an `at_exit` stop.

### Feature support code

`features/support/` contains small servers/clients used by cucumber scenarios (HTTP/TCP/gRPC). Example:

- `features/support/http_server.rb` defines a Sinatra app for `/hello` and health endpoints.

### Process fixture

Scenarios start a local process via `features/support/bin/start` (referenced in step definitions and YAML configs like `features/configs/processes.yml`).

## Library architecture (high level)

### Entry point and global state

- `lib/nonnative.rb` defines the `Nonnative` module singleton API:
  - `configure { |config| ... }`
  - `start` / `stop`
  - `clear`, `reset`
  - `pool` is created on `start` (`Nonnative::Pool.new(configuration)`).

### Configuration objects

- `Nonnative::Configuration` (`lib/nonnative/configuration.rb`) holds arrays of:
  - `processes` (`Nonnative::ConfigurationProcess`)
  - `servers` (`Nonnative::ConfigurationServer`)
  - `services` (`Nonnative::ConfigurationService`)

It can be populated either:

- programmatically via `config.process { ... }`, `config.server { ... }`, `config.service { ... }`
- via YAML using `config.load_file(path)` which calls `Config.load_files(...)` (the `config` gem)

Proxies are configured via `ConfigurationProxy` (`lib/nonnative/configuration_proxy.rb`) and attached to runners as a hash.

### Runners and lifecycle

There are three runtime “runner” types, all subclassing `Runner` (`lib/nonnative/runner.rb`):

- `Nonnative::Process` (`lib/nonnative/process.rb`): `spawn(...)` + `Process.kill` / `waitpid2`.
- `Nonnative::Server` (`lib/nonnative/server.rb`): `Thread.new { perform_start }` + `perform_stop`.
- `Nonnative::Service` (`lib/nonnative/service.rb`): no process management; proxy only.

`Nonnative::Pool` (`lib/nonnative/pool.rb`) owns collections of runners and orchestrates start/stop:

- starts **services first**, then servers/processes
- stops **processes/servers first**, then services
- readiness is determined via `Nonnative::Port#open?` / `#closed?` (`lib/nonnative/port.rb`) which repeatedly tries `TCPSocket.new(host, port)` inside a timeout.

### Proxies

Proxy selection is keyed by `kind`:

- mapping: `Nonnative.proxies` in `lib/nonnative.rb`
- default proxy config values: `ConfigurationProxy#initialize` sets kind `none`, host `0.0.0.0`, wait `0.1`, etc.

Implemented proxies:

- `Nonnative::NoProxy` (`lib/nonnative/no_proxy.rb`)
- `Nonnative::FaultInjectionProxy` (`lib/nonnative/fault_injection_proxy.rb`)
  - states: `:none`, `:close_all`, `:delay`, `:invalid_data`
  - delegates behavior to socket-pair classes via `SocketPairFactory` (`lib/nonnative/socket_pair_factory.rb`).

### Go executable helper

There is a helper for building a Go *test binary* command line with optional profiling/trace/coverage flags:

- `Nonnative.go_executable` in `lib/nonnative.rb`
- `Nonnative::GoCommand` in `lib/nonnative/go_command.rb`

This is used when YAML process config has a `go:` section (see `Configuration#command` in `lib/nonnative/configuration.rb`).

## Style and conventions

- Ruby style is enforced by RuboCop (`.rubocop.yml`):
  - Target Ruby 3.4
  - Line length 150
  - `Style/Documentation` disabled
- `.editorconfig`:
  - `indent_size = 2` for most files
  - **Makefiles use tabs**
- Many Ruby files use `# frozen_string_literal: true`.

## CI notes

CircleCI runs (see `.circleci/config.yml`):

- `make source-key` (defined in `bin/build/make/git.mak`) to generate `.source-key` used for caching
- `make dep`, `make clean-dep`
- `make lint`, `make features`
- uploads `test/reports` artifacts

## Common gotchas

- **Submodule required**: root `Makefile` only includes `bin/...` make fragments; without `bin/` present/updated, `make` won’t work.
- **SSH-only submodule URL**: `.gitmodules` uses `git@github.com:...`; CI or local environments without SSH keys will fail to init the submodule.
- **Local Ruby/Bundler mismatch can break native extensions**: on macOS, `make lint`/`bundle exec ...` may fail if the Ruby used to install gems differs from the Ruby used to run them (example error seen: `prism.bundle` missing `libruby.3.4.dylib`).
- **Requiring `nonnative` loads Cucumber DSL**: `lib/nonnative.rb` requires `lib/nonnative/cucumber.rb`, which calls `World(...)`. Outside a Cucumber runtime this can raise (example error seen: `Cucumber::Glue::Dsl.build_rb_world_factory`).
- **Reports directory**: Cucumber report profile writes into `test/reports/` and the repo keeps a `test/reports/.keep` file.
- **Port checks can be flaky if ports are reused**: readiness is purely `TCPSocket`-based (`lib/nonnative/port.rb`), so ensure test fixtures bind expected ports.

## Where to look first when changing behavior

- Lifecycle orchestration: `lib/nonnative.rb`, `lib/nonnative/pool.rb`
- Readiness / timeouts: `lib/nonnative/port.rb`, `lib/nonnative/timeout.rb`
- Process management: `lib/nonnative/process.rb`
- Proxies / fault injection: `lib/nonnative/fault_injection_proxy.rb`, `lib/nonnative/socket_pair_factory.rb`
- Cucumber integration: `lib/nonnative/cucumber.rb`, `lib/nonnative/startup.rb`, `features/support/env.rb`
