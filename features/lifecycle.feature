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

  Scenario: Process stop timeouts are reported even when shutdown ports close
    Given I configure the system with a process that does not exit during stop
    And I start the system
    When I attempt to stop the system
    Then stopping the system should raise an error containing:
      | Stopped no_exit_process with id       |
      | though the process did not exit in time |
    And the process "no_exit_process" should no longer exist
    And the port "12410" should be closed

  Scenario: Rollback errors are included in start failures
    Given I configure a pool that fails to start and raises on rollback
    When I attempt to start the system
    Then starting the system should raise an error containing "Rollback failed with StandardError: boom on rollback"

  Scenario: Rollback releases resources acquired during server construction
    Given I configure the system with a constructed server before a failing server
    When I attempt to start the system
    Then starting the system should raise an error containing "HTTP server requires at least one service mount"
    And starting the system should not raise an error containing "Cannot stop before starting"
    And the port "12430" should be reusable

  Scenario: Server stop waits for owned-thread cleanup within the timeout
    Given I configure the system with server cleanup and a timeout of 0.5 seconds
    And I start the system
    When I attempt to stop the system
    Then stopping the system should not raise an error
    And the server cleanup should be complete

  Scenario: Server stop reports owned-thread cleanup beyond the timeout
    Given I configure the system with server cleanup and a timeout of 0.05 seconds
    And I start the system
    When I attempt to stop the system
    Then stopping the system should raise an error containing "server thread did not exit in time"

  Scenario: Server start recovers after a stop that exceeded the timeout
    Given I configure the system with a restartable server and a timeout of 0.05 seconds
    And I start the system
    When I attempt to stop the system
    Then stopping the system should raise an error containing "server thread did not exit in time"
    When I start the system
    Then the port "12435" should be open

  Scenario: Process rollback timeouts are included in start failures
    Given I configure the system with a process that does not exit during rollback
    When I attempt to start the system
    Then starting the system should raise an error containing:
      | Rollback failed for rollback_process with id |
      | because the process did not exit in time     |
    And the process "rollback_process" should no longer exist
    And the port "12411" should be closed

  Scenario: Process readiness requires every configured port to open
    Given I configure the system with a process that opens only one configured port
    When I attempt to start the system
    Then starting the system should raise an error containing "Started partial_ports_process with id"
    And starting the system should raise an error containing "though did not respond in time"
    And starting the system should raise an error containing "127.0.0.1:12415, 127.0.0.1:12416"
    And starting the system should raise an error containing "log: test/reports/12_415.log"

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

  Scenario: Service start failures stop later lifecycle tiers
    When I start a pool with a failing service and recording runners
    Then the lifecycle errors should include "Start failed for runner 'service_1': StandardError - boom on service start"
    And the lifecycle order should be empty

  Scenario: Pool collects service stop lifecycle errors for unnamed services
    When I stop a pool with a failing unnamed service
    Then the lifecycle errors should include "Stop failed for Nonnative::Features::FailingService: StandardError - boom on service stop"

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
    And I receive data from the service with a 0.1 second timeout
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

  Scenario Outline: Zero and nil timeouts skip timed work
    When I perform a nonnative timeout with <duration>
    Then the nonnative timeout should return false

    Examples:
      | duration |
      | zero     |
      | nil      |

  Scenario: Negative timeouts remain invalid
    When I perform a nonnative timeout with negative
    Then the nonnative timeout should raise an argument error
