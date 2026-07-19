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

  Scenario: A pass-through service proxy delivers the response after a client half-closes
    Given I configure the system programmatically with services
    And I start the system
    When I connect to the service
    And I send "test" to the service and close the write side
    And I receive data from the service
    Then I should receive "test" from the service

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
  Scenario: A jittered delay proxy keeps latency within the jitter envelope
    Given I configure the system programmatically with services with jitter
    And I start the system
    And I set the proxy for service 'service_1' to 'delay'
    When I connect to the service
    And I send "test" to the service and receive the response
    Then I should receive "test" from the service
    And the round trip should take between 0.2 and 1.5 seconds

  @reset
  Scenario: A negative delay preserves pass-through
    Given I configure the system programmatically with services with a negative delay
    And I start the system
    And I set the proxy for service 'service_1' to 'delay'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive "test" from the service

  @reset
  Scenario: A bandwidth-limited service proxy throttles transfer
    Given I configure the system programmatically with services with a bandwidth limit
    And I start the system
    And I set the proxy for service 'service_1' to 'bandwidth'
    When I connect to the service
    And I send a 4096 byte payload to the service and receive the response
    Then I should receive the payload back
    And the transfer should take at least 0.8 seconds

  @reset
  Scenario: A service proxy truncates responses after a byte limit
    Given I configure the system programmatically with services with a response byte limit
    And I start the system
    And I set the proxy for service 'service_1' to 'limit_data'
    When I connect to the service
    And I send a 512 byte payload to the service and receive the response
    Then I should receive the first 128 bytes of the payload

  @reset
  Scenario: A non-positive response byte limit preserves pass-through
    Given I configure the system programmatically with services with a zero response byte limit
    And I start the system
    And I set the proxy for service 'service_1' to 'limit_data'
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

  @reset
  Scenario: A sliced service proxy fragments the response
    Given I configure the system programmatically with services with a response slicer
    And I start the system
    And I set the proxy for service 'service_1' to 'slicer'
    When I connect to the service
    And I send "test" to the service and receive it in fragments
    Then I should receive the payload in more than one fragment
    And the reassembled fragments should equal the payload

  @reset
  Scenario: A non-positive slice size preserves pass-through
    Given I configure the system programmatically with services with a zero slice size
    And I start the system
    And I set the proxy for service 'service_1' to 'slicer'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive "test" from the service

  @reset
  Scenario: A flaky service proxy fails only some connections
    Given I configure the system programmatically with services with a flaky proxy
    And I start the system
    And I set the proxy for service 'service_1' to 'flaky'
    When I connect to the service 30 times and send "test"
    Then I should see both successful and failed connections

  @reset
  Scenario: A non-positive probability preserves pass-through
    Given I configure the system programmatically with services with a zero flaky probability
    And I start the system
    And I set the proxy for service 'service_1' to 'flaky'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive "test" from the service

  Scenario: Looking up a missing service proxy fails
    Given I configure the system programmatically with services
    And I start the system
    When I try to find the proxy for service 'non_existent'
    Then I should get a proxy not found error
