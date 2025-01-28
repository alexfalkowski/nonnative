@clear
Feature: Benchmark
  Allows us to check that start and stop responds in adequate time

  @manual
  Scenario: Start the system within an adequate time
    When I configure the system through configuration with processes
    Then starting the system should happen within an adequate time

  Scenario: Stop the system within an adequate time
    Given I configure the system through configuration with processes
    When I start the system
    Then stopping the system should happen within an adequate time

  @manual
  Scenario: Start nonnative with a long start up time server will error
    When I configure the system programmatically with a no op server
    Then starting the system should raise an error

  Scenario: Stop nonnative with a long stopping time server will error
    Given I configure the system programmatically with a no stop server
    When I start the system
    Then stopping the system should raise an error
