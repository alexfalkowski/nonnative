Feature: Benchmark nonnative

  Allows us to check that start and stop responds in adequate time

  Scenario: Start nonnative
    When we configure nonnative through configuration
    Then starting nonnative should happen with an adequate time

  Scenario: Stop nonnative
    Given we configure nonnative through configuration
    When we start nonnative
    Then stoping nonnative should happen with an adequate time
