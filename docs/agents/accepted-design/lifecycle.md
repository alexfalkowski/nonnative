# Accepted design for lifecycle

Part of the [accepted-design index](../accepted-design.md).

## Startup order

The pool handles externally managed services first, then in-process servers,
then managed processes. Multiple managed processes are supported. Typical
suites manage one system process and model its dependencies as services or
in-process servers, which are started or checked first. Revisit process-to-process
`depends_on`, dependency graphs, or topological startup when downstream usage
evidence supports them or the task explicitly changes the lifecycle model.

[Pool startup](../../../lib/nonnative/pool.rb)

## Service and process readiness

Externally managed services support optional TCP readiness against an explicit
dependency endpoint. HTTP and gRPC readiness belong to managed processes, where
the caller configures the application's health endpoints. Revisit HTTP or gRPC
service readiness only when the task explicitly changes the service readiness
model.

Managed processes wait for TCP ports and can then poll optional `http` and
`grpc` health probes. These probes match how the containerized systems normally
tested with Nonnative expose readiness. Revisit log-message readiness
(`kind: 'log'`) only when the task explicitly changes process readiness.

[Service readiness](../../../lib/nonnative/configuration_service_readiness.rb) · [Process readiness](../../../lib/nonnative/configuration_readiness.rb)

## Process working directory

Managed processes inherit the parent working directory. Nonnative normally runs
from the test folder that owns `test/nonnative.yml`, relative configuration paths,
logs, and reports. Revisit per-process `cwd` or `chdir` support only when the task
explicitly changes working-directory behavior.

[Process runner](../../../lib/nonnative/process.rb)
