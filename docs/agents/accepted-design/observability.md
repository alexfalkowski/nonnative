# Accepted design for observability

Part of the [accepted-design index](../accepted-design.md).

## HTTP endpoints and metrics

`Nonnative::Observability` uses `/<name>/{healthz,livez,readyz,metrics}` to follow
the go-service convention. Callers with other endpoint paths can use
`Nonnative::HTTPClient` directly. Revisit configurable paths only when the task
explicitly changes the observability endpoint model.

`Nonnative::Observability#metrics` exposes the raw Prometheus exposition body.
Callers parse samples or assert metric values with a parser of their choice.
Revisit a built-in parser only when the task explicitly changes metric-value
parsing in the observability client.

[Observability client](../../../lib/nonnative/observability.rb) · [HTTP client](../../../lib/nonnative/http_client.rb)

## gRPC health assertions

`Nonnative::GRPCHealth#check` returns the full `HealthCheckResponse`. Tests can
assert any status directly, for example `check.status == :NOT_SERVING`.
`serving?` is a convenience predicate. Revisit `not_serving?`, a `status:`
helper, or a streaming `Watch` wrapper only when the task explicitly expands
the gRPC health assertion surface.

[gRPC health client](../../../lib/nonnative/grpc_health.rb)
