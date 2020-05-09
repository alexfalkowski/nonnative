Feature: Benchmark nonnative

  Allows us to check that start and stop responds in adequate time

  @manual
  Scenario: Start nonnative within an adequate time
    When I configure nonnative through configuration with processes
    Then starting nonnative should happen within an adequate time

  Scenario: Stop nonnative within an adequate time
    Given I configure nonnative through configuration with processes
    When I start nonnative
    Then stoping nonnative should happen within an adequate time

  @manual
  Scenario: Start nonnative with a long start up time server will error
    When I configure nonnative programatially with a slow starting server
    Then starting nonnative should raise an error

  Scenario: Stop nonnative with a long stopping time server will error
    When I configure nonnative programatially with a slow stopping server
    When I start nonnative
    Then stopping nonnative should raise an error
