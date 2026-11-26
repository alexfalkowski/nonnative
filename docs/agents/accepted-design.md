# Accepted design

This index records Nonnative's accepted design choices, tradeoffs, and support
boundaries. The area files carry the same weight as [AGENTS.md](../../AGENTS.md).

Read the relevant area files before proposing a change or recording a finding
or audit entry. Apply each decision within its documented scope and record new
owner-accepted decisions in the relevant area file.

- [Configuration](accepted-design/configuration.md) covers YAML loading and
  pre-start lookups.
- [Lifecycle](accepted-design/lifecycle.md) covers runner ordering, readiness,
  and the process working directory.
- [Observability](accepted-design/observability.md) covers HTTP endpoint paths,
  metrics responses, and gRPC health assertions.
- [Proxies](accepted-design/proxies.md) covers listener shutdown and the live
  HTTP proxy fixture.
- [Testing](accepted-design/testing.md) covers local and downstream coverage,
  Cucumber helpers, benchmark scenarios, and test proto tooling.
- [Tokens](accepted-design/tokens.md) covers signing key file provisioning.
