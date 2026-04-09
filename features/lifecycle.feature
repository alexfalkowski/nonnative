@clear
Feature: Lifecycle
  Allows us to verify lifecycle error handling and edge cases.

  Scenario: Start errors from the pool are normalized
    Given I configure a pool that raises on start
    Then starting the system should raise an error containing "Start failed with StandardError: boom on start"

  Scenario: Stop errors from the pool are normalized
    Given I configure a pool that raises on stop
    Then stopping the system should raise an error containing "Stop failed with StandardError: boom on stop"

  Scenario: Rollback errors are included in start failures
    Given I configure a pool that fails to start and raises on rollback
    Then starting the system should raise an error containing "Rollback failed with StandardError: boom on rollback"

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
