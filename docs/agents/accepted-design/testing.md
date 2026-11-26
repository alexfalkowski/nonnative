# Accepted design for testing

Part of the [accepted-design index](../accepted-design.md).

## Downstream coverage

Nonnative is a test-support gem used by downstream projects. Those suites cover
the following behavior. Revisit local coverage when the task explicitly
changes the corresponding behavior.

- The `@startup` Cucumber hook, public proxy reset steps, and `@reset` hook.
- Configuration and pool clearing through `Nonnative.clear`.
- `Nonnative.go_argv` and `Nonnative.go_command` flag combinations, including
  `-test.*` flags and tool filtering.
- Service proxy round trips against real dependencies. The local success
  scenario checks that a client can connect.

Revisit isolated gem build and install smoke coverage only when the task
explicitly addresses release packaging or gem publication validation.

[Cucumber hooks and steps](../../../lib/nonnative/cucumber.rb) · [Public entry point](../../../lib/nonnative.rb) · [Service scenarios](../../../features/services.feature)

## Repository-local Cucumber steps

Message-specific start and stop assertions and attempted-stop success assertions
belong to Nonnative's own lifecycle scenarios. The liveness, readiness, and
metrics endpoint assertions in the server steps serve the same purpose for the
observability scenarios. Revisit exposing either set in `lib/nonnative/cucumber.rb`
when downstream usage evidence supports it or the task explicitly expands the
corresponding public assertion steps.

[Lifecycle steps](../../../features/step_definitions/lifecycle_steps.rb) · [Server steps](../../../features/step_definitions/servers_steps.rb)

## Benchmark-tagged lifecycle coverage

Full repository validation runs both `make features` and `make benchmarks`.
Rollback and timeout lifecycle scenarios in `features/benchmark.feature` run
under the latter. Revisit their placement only when the task explicitly changes
validation target composition.

[Benchmark scenarios](../../../features/benchmark.feature) · [CircleCI configuration](../../../.circleci/config.yml)

## Test protos and generated stubs

`test/Makefile` uses the shared Buf fragment as-is, including the `breaking`
target's `subdir=api` comparison. The test-only `test/buf.yaml` is outside the
required local lint surface. Revisit these choices only when the task
explicitly changes test proto breaking checks, test proto linting, or Buf
validation, as applicable.

Update the Ruby gRPC stubs under `test/grpc/` on demand when the test proto
changes. The stubs may carry manual require-path adjustments. Verify that the
generated Ruby loads before accepting generator-only rewrites. Revisit
automated freshness checks only when the task explicitly changes test proto
generation or generated-file validation. Require `make -C test stale` only
when the task explicitly changes test proto generation.

[Test Makefile](../../../test/Makefile) · [Buf configuration](../../../test/buf.yaml) · [Ruby gRPC stubs](../../../test/grpc/)
