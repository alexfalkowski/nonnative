# Accepted design for configuration

Part of the [accepted-design index](../accepted-design.md).

## YAML data loading

`Nonnative::ConfigurationFile` loads YAML as pure data, without evaluating ERB,
deserializing arbitrary Ruby objects, or expanding `${VAR}`. For values that
vary by environment, read `ENV` in Ruby configuration and use
`config.process`, `config.server`, or `config.service` alongside `config.load_file`
as needed. Revisit interpolation only when the task explicitly changes YAML
environment-variable substitution.

Unknown structural keys may be ignored. The loader and configuration classes
still validate syntax, safety, and supported value shapes. Revisit strict
unknown-key diagnostics or a configuration-lint mode only when the task
explicitly changes YAML validation behavior.

[YAML loader](../../../lib/nonnative/configuration_file.rb) · [Configuration](../../../lib/nonnative/configuration.rb)

## Pre-start configuration lookup

`Nonnative::Configuration` exposes `process_by_name` before startup. Revisit
adding `server_by_name` or `service_by_name` to configuration when downstream
usage evidence supports them or the task explicitly changes the pre-start
lookup API.

[Configuration lookup](../../../lib/nonnative/configuration.rb) · [Runtime pool](../../../lib/nonnative/pool.rb)
