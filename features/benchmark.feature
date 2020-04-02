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
