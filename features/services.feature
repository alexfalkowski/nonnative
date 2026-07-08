@acceptance @service @proxy @manual @clear
Feature: Service proxies
  Connect to externally managed services through nonnative proxies.

  Scenario Outline: Services stay reachable when configured <source>
    Given I configure the system <source> with services
    And I start the system
    When I connect to the service
    Then I should have a successful connection

    Examples:
      | source           |
      | programmatically |

    @config
    Examples:
      | source                |
      | through configuration |

  Scenario: Service proxies expose the upstream endpoint
    Given I configure the system programmatically with services
    And I start the system
    Then the proxy for service "service_1" should use host "127.0.0.1" and port 30000

  Scenario: Service TCP readiness gates startup
    Given I configure the system programmatically with service TCP readiness
    And I start the system
    When I connect to the service
    Then I should have a successful connection

  Scenario: Service TCP readiness failures are reported during startup
    Given I configure the system programmatically with missing service TCP readiness
    When I attempt to start the system
    Then starting the system should raise an error containing "readiness: 127.0.0.1:30001"

  Scenario: Service TCP readiness failures stop startup before processes
    Given I configure the system programmatically with a process and missing service TCP readiness
    When I attempt to start the system
    Then starting the system should raise an error containing "readiness: 127.0.0.1:30001"
    And the service readiness process side effect should not happen

  Scenario: Service TCP readiness resolution failures are reported during startup
    Given I configure the system programmatically with unresolvable service TCP readiness
    When I attempt to start the system
    Then starting the system should raise an error containing "Readiness check failed for runner 'service_1': Socket::ResolutionError"

  @reset
  Scenario: Services can run without proxies
    Given I configure the system programmatically with services without proxies
    And I start the system
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive "test" from the service
    And the proxy for service "service_1" should use host "127.0.0.1" and port 30000

  Scenario: Missing proxy upstreams close service connections
    Given I configure the system programmatically with services and missing upstreams
    And I start the system
    When I connect to the service
    And I receive data from the service
    Then I should receive a connection error from the service
    And I should see a log entry of "could not handle the connection" in the file "test/reports/proxy_service_1.log"

  @reset
  Scenario: Closing the service proxy interrupts reads
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'close_all'
    When I connect to the service
    And I receive data from the service
    Then I should receive a connection error from the service

  @reset
  Scenario: A reset service proxy resets client connections
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'reset_peer'
    When I connect to the service
    And I receive data from the service
    Then I should receive a connection reset from the service

  Scenario: Stopping a service proxy while clients connect succeeds
    Given I configure the system programmatically with services
    And I start the system
    When I stop the service runner "service_1" while clients connect
    Then stopping the service runner should succeed

  @reset
  Scenario: A delayed service proxy still allows responses
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'delay'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive "test" from the service

  @reset
  Scenario: A timed-out service proxy stalls responses
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'timeout'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service with a 0.1 second timeout
    Then I should receive a timeout from the service

  @reset
  Scenario: Invalid proxy data changes the service response
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'invalid_data'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive an invalid service response that is not "test"

  @reset
  Scenario: Invalid proxy data corrupts a delimiter-only service response
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'invalid_data'
    When I connect to the service
    And I send "" to the service
    And I receive data from the service
    Then I should receive an invalid service response that is not ""

  Scenario: Looking up a missing service proxy fails
    Given I configure the system programmatically with services
    And I start the system
    When I try to find the proxy for service 'non_existent'
    Then I should get a proxy not found error
