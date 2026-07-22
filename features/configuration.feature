@contract @config @clear
Feature: Configuration loading
  Preserve the documented YAML semantics for services, proxies, and runner defaults.

  Scenario: Service YAML entries populate service configurations
    Given I load a temporary configuration with a service entry
    Then the configuration should contain 1 service entry and 0 process entries

  Scenario: YAML keeps service and proxy endpoints separate
    Given I load a temporary configuration with split service and proxy endpoints
    Then the configured service "service_1" should use host "127.0.0.1" and port 20006
    And the configured service "service_1" proxy should use host "127.0.0.1" and port 30000

  Scenario: YAML maps service TCP readiness
    Given I load a temporary configuration with service TCP readiness
    Then the configured service "service_1" TCP readiness should use host "127.0.0.1" and port 30000

  Scenario: YAML maps multiple runner ports
    Given I load a temporary configuration with multiple runner ports
    Then the configured process "multi_port_process" should use ports:
      | 12420 |
      | 12421 |

  Scenario: YAML maps process HTTP readiness
    Given I load a temporary configuration with process HTTP readiness
    Then the configured process "ready_process" HTTP readiness should use port 12427 and path "/test/readyz"

  Scenario: YAML maps process gRPC readiness
    Given I load a temporary configuration with process gRPC readiness
    Then the configured process "ready_process" gRPC readiness should use port 12429 and service "nonnative.v1.GreeterService"

  Scenario: YAML rejects map process readiness
    When I attempt to load a temporary configuration with map process readiness
    Then loading the configuration should fail with an argument error containing "Process readiness must be a list of checks"

  Scenario Outline: YAML rejects incomplete process HTTP readiness
    When I attempt to load a temporary configuration with process HTTP readiness missing "<field>"
    Then loading the configuration should fail with an argument error containing "Process readiness requires '<field>'"

    Examples:
      | field |
      | port  |
      | path  |

  Scenario: YAML rejects incomplete process gRPC readiness
    When I attempt to load a temporary configuration with process gRPC readiness missing "service"
    Then loading the configuration should fail with an argument error containing "Process readiness requires 'service'"

  Scenario: YAML rejects process readiness without a kind
    When I attempt to load a temporary configuration with process HTTP readiness missing "kind"
    Then loading the configuration should fail with an argument error containing "Process readiness requires 'kind'"

  Scenario: YAML rejects unsupported process readiness kinds
    When I attempt to load a temporary configuration with process readiness kind "tcp"
    Then loading the configuration should fail with an argument error containing "Process readiness kind must be one of: http, grpc"

  Scenario Outline: YAML rejects process HTTP readiness paths that are not valid path-only values
    When I attempt to load a temporary configuration with process HTTP readiness path "<path>"
    Then loading the configuration should fail with an argument error containing "Process readiness path must be path-only"

    Examples:
      | path                          |
      | http://example.invalid/readyz |
      | /test readyz                  |
      | //example.invalid/readyz      |

  Scenario: YAML rejects singular process ports
    When I attempt to load a temporary configuration with a singular runner port
    Then loading the configuration should fail with an argument error containing "Use 'ports' instead of 'port'"

  Scenario: YAML rejects a process with no command or go
    When I attempt to load a temporary configuration with a process missing a command
    Then loading the configuration should fail with an argument error containing "Process 'commandless_process' requires 'command' or 'go'"

  Scenario: Programmatic configuration rejects a process with no command
    When I attempt to configure a process without a command
    Then loading the configuration should fail with an argument error containing "Process 'commandless_process' requires 'command' or 'go'"

  Scenario: YAML rejects plural service ports
    When I attempt to load a temporary configuration with plural service ports
    Then loading the configuration should fail with an argument error containing "Use 'port' instead of 'ports'"

  Scenario: Programmatic configuration rejects plural service ports
    When I attempt to configure a service with plural ports
    Then loading the configuration should fail with an argument error containing "Use 'port' instead of 'ports'"

  Scenario: Programmatic configuration rejects reading plural service ports
    When I attempt to read plural ports from a configured service
    Then loading the configuration should fail with an argument error containing "Use 'port' instead of 'ports'"

  Scenario: YAML maps proxy options
    Given I load a temporary configuration with proxy options
    Then the configured service "service_1" proxy option "delay" should be 5

  Scenario: YAML rejects process proxies
    When I attempt to load a temporary configuration with a process proxy
    Then loading the configuration should fail with an argument error containing "processes do not support 'proxy'"

  Scenario: YAML rejects server proxies
    When I attempt to load a temporary configuration with a server proxy
    Then loading the configuration should fail with an argument error containing "servers do not support 'proxy'"

  Scenario: YAML rejects server readiness
    When I attempt to load a temporary configuration with server readiness
    Then loading the configuration should fail with an argument error containing "servers do not support 'readiness'"

  Scenario Outline: YAML rejects incomplete service TCP readiness
    When I attempt to load a temporary configuration with service TCP readiness missing "<field>"
    Then loading the configuration should fail with an argument error containing "Service readiness requires '<field>'"

    Examples:
      | field |
      | host  |
      | port  |

  Scenario: YAML rejects unsupported service readiness kinds
    When I attempt to load a temporary configuration with service readiness kind "http"
    Then loading the configuration should fail with an argument error containing "Service readiness kind must be one of: tcp"

  Scenario: Server YAML class entries resolve to server implementations
    Given I load a temporary configuration with a server entry
    Then the configured server "server_1" should use class "Nonnative::Features::TCPServer"

  Scenario: Top-level wait does not override runner wait defaults
    Given I load a temporary configuration with a top-level wait and a process
    Then the configured process "default_wait_process" should have wait 0.1

  Scenario: Missing runner timeouts default to bounded lifecycle checks
    Given I load a temporary configuration with omitted runner timeouts
    Then the configured process "default_timeout_process" should have timeout 1.0
    And the configured server "default_timeout_server" should have timeout 1.0

  Scenario: YAML preserves explicit runner timeouts
    Given I load a temporary configuration with explicit runner timeouts
    Then the configured process "explicit_timeout_process" should have timeout 2.5
    And the configured server "explicit_timeout_server" should have timeout 3.5

  Scenario: Missing hosts default to loopback
    Given I load a temporary configuration with omitted hosts
    Then the configured process "default_host_process" should use host "127.0.0.1"

  Scenario: YAML configuration does not evaluate ERB
    Given I load a temporary configuration containing ERB
    Then the ERB side effect should not happen
    And the configuration name should be the ERB source

  Scenario: YAML configuration rejects arbitrary Ruby objects
    When I attempt to load a temporary configuration with a Ruby object tag
    Then loading the configuration should fail with a YAML safety error

  Scenario Outline: YAML configuration rejects malformed documents
    When I attempt to load a temporary configuration with "<kind>" YAML
    Then loading the configuration should fail with an argument error containing "<message>"

    Examples:
      | kind         | message                     |
      | scalar root  | must contain a YAML mapping |
      | syntax error | YAML syntax error occurred  |
