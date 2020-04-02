Feature: Benchmark nonnative

  Allows us to check that start and stop responds in adequate time

  Scenario: Start nonnative within an adequate time
    When I configure nonnative through configuration
    Then starting nonnative should happen within an adequate time

  Scenario: Stop nonnative within an adequate time
    Given I configure nonnative through configuration
    When I start nonnative
    Then stoping nonnative should happen within an adequate time
