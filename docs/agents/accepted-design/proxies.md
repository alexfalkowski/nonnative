# Accepted design for proxies

Part of the [accepted-design index](../accepted-design.md).

## Fault-injection listener shutdown

`Nonnative::FaultInjectionProxy` owns its listener and its listening socket.
Shutdown closes the socket, then kills and joins the listener thread because
closing the socket may leave `accept` blocked on some platforms. Revisit the
listener join as a reliability concern when the task explicitly changes proxy
shutdown or when a normal-use reproducer, failing CI, or a platform-specific
hang demonstrates a problem.

[Proxy shutdown](../../../lib/nonnative/fault_injection_proxy.rb)

## Live HTTP proxy fixture

The configured HTTP proxy feature intentionally uses `www.afalkowski.com`
through its fixture. Revisit the external dependency only when the task
explicitly calls for fully hermetic HTTP proxy fixtures.

[HTTP proxy feature](../../../features/http_proxies.feature) · [HTTP proxy fixture](../../../features/support/http_proxy_server.rb)
