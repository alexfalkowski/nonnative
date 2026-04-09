@clear
Feature: Benchmark
  Allows us to check that start and stop responds in adequate time

  @manual
  Scenario: Start the system within an adequate time
    Given I configure the system through configuration with processes
    Then starting the system should happen within an adequate time

  Scenario: Stop the system within an adequate time
    Given I configure the system through configuration with processes
    When I start the system
    Then stopping the system should happen within an adequate time

  @manual
  Scenario: Start nonnative with a long start up time server will error
    Given I configure the system programmatically with a no op server
    When I attempt to start the system
    Then starting the system should raise an error

  @manual
  Scenario: Start nonnative with a start error will rollback started runners
    Given I configure the system programmatically with a start error server
    When I attempt to start the system
    Then starting the system should raise an error
    And the port '14002' should be closed

  @manual
  Scenario: Start nonnative with a fast exiting process will rollback its proxy
    Given I configure the system programmatically with a fast exiting process
    When I attempt to start the system
    Then starting the system should raise an error
    And the port '14006' should be closed

  Scenario: Stop nonnative with a long stopping time server will error
    Given I configure the system programmatically with a no stop server
    When I start the system
    And I attempt to stop the system
    Then stopping the system should raise an error

  Scenario: Stop nonnative with a stop error will still stop later runners
    Given I configure the system programmatically with a stop error server
    When I start the system
    And I attempt to stop the system
    Then stopping the system should raise an error
    And the port '14005' should be closed
