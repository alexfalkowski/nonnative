@contract @clear
Feature: Lifecycle
  Allows us to verify lifecycle error handling and edge cases.

  Scenario: Start errors from the pool are normalized
    Given I configure a pool that raises on start
    When I attempt to start the system
    Then starting the system should raise an error containing "Start failed with StandardError: boom on start"

  Scenario: Stop errors from the pool are normalized
    Given I configure a pool that raises on stop
    When I attempt to stop the system
    Then stopping the system should raise an error containing "Stop failed with StandardError: boom on stop"

  Scenario: Rollback errors are included in start failures
    Given I configure a pool that fails to start and raises on rollback
    When I attempt to start the system
    Then starting the system should raise an error containing "Rollback failed with StandardError: boom on rollback"

  Scenario: Pool starts services before servers and processes
    When I start a pool with ordered services, servers, and processes
    Then the lifecycle errors should be empty
    And the lifecycle order should be:
      | service_1 start |
      | server_1 start  |
      | process_1 start |

  Scenario: Pool stops processes and servers before services
    When I stop a pool with ordered services, servers, and processes
    Then the lifecycle errors should be empty
    And the lifecycle order should be:
      | process_1 stop |
      | server_1 stop  |
      | service_1 stop |

  Scenario: Pool collects service lifecycle errors for unnamed services
    When I start a pool with a failing unnamed service
    Then the lifecycle errors should include "Start failed for Nonnative::Features::FailingService: StandardError - boom on service start"

  Scenario: Pool collects readiness errors for unnamed runners
    When I start a pool with a failing unnamed port check
    Then the lifecycle errors should include "Readiness check failed for Nonnative::Features::FailingRunner: StandardError - boom on readiness"

  Scenario: Pool collects shutdown errors for unnamed runners
    When I stop a pool with a failing unnamed port check
    Then the lifecycle errors should include "Shutdown check failed for Nonnative::Features::FailingRunner: StandardError - boom on shutdown"

  Scenario: Process existence checks return false for a reaped pid
    When I check whether a reaped process still exists
    Then the process should no longer exist

  Scenario: Clear resets memoized logger and observability clients
    When I clear after memoizing logger and observability
    Then the logger should be recreated for the new configuration
    And the observability client should be recreated for the new configuration

  @service
  Scenario: Stopping a service runner closes active proxy connections
    Given I configure the system programmatically with services
    And I start the system
    When I connect to the service
    And I send "ping" to the service
    And I stop the service runner "service_1"
    And I receive data from the service
    Then I should receive a connection error from the service

  Scenario: Requiring nonnative outside Cucumber succeeds
    When I require "nonnative" in a subprocess
    Then the subprocess should exit successfully
    And the subprocess output should contain "ok"

  Scenario: Requiring nonnative/startup starts immediately and stops at exit
    When I require "nonnative/startup" in an instrumented subprocess
    Then the subprocess should exit successfully
    And the subprocess output should be:
      | started |
      | stopped |
