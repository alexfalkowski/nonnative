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

  Scenario: Server YAML class entries resolve to server implementations
    Given I load a temporary configuration with a server entry
    Then the configured server "server_1" should use class "Nonnative::Features::TCPServer"

  Scenario: Top-level wait does not override runner wait defaults
    Given I load a temporary configuration with a top-level wait and a process
    Then the configured process "default_wait_process" should have wait 0.1

  Scenario: Missing hosts default to loopback
    Given I load a temporary configuration with omitted hosts
    Then the configured process "default_host_process" should use host "127.0.0.1"
    And the configured process "default_host_process" proxy should use host "127.0.0.1"

  Scenario: YAML configuration does not evaluate ERB
    Given I load a temporary configuration containing ERB
    Then the ERB side effect should not happen
    And the configuration name should be the ERB source

  Scenario: YAML configuration rejects arbitrary Ruby objects
    When I attempt to load a temporary configuration with a Ruby object tag
    Then loading the configuration should fail with a YAML safety error
