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
  Scenario: Invalid proxy data changes the service response
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'invalid_data'
    When I connect to the service
    And I send "test" to the service
    And I receive data from the service
    Then I should receive an invalid service response that is not "test"

  Scenario: Looking up a missing service proxy fails
    Given I configure the system programmatically with services
    And I start the system
    When I try to find the proxy for service 'non_existent'
    Then I should get a proxy not found error
