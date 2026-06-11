@acceptance @manual @clear
Feature: Process runners
  Start managed processes and exercise their client-facing TCP endpoints.

  Scenario Outline: Processes echo TCP messages when configured <source>
    Given I configure the system <source> with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response

    Examples:
      | source           |
      | programmatically |

    @config
    Examples:
      | source                |
      | through configuration |

  Scenario: Process activity is logged and stays within the memory budget
    Given I configure the system programmatically with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response
    And I should see a log entry of "test" for process 'start_1'
    And I should see a log entry of "test" in the file "test/reports/12_321.log"
    And the process 'start_1' should consume less than '40mb' of memory

  Scenario: Process argv commands do not invoke the shell
    Given I configure the system programmatically with an argv process
    And I start the system
    When I send "test" with the TCP client 'argv_process' to the process
    Then I should receive a TCP "test" response from the process
    And the argv process shell side effect should not happen

  Scenario: Legacy string process commands invoke the shell
    Given I configure the system programmatically with a shell string process
    And I start the system
    When I send "test" with the TCP client "shell_string_process" to the process
    Then I should receive a TCP "test" response from the process
    And the shell string process side effect should happen

  Scenario: Processes without a stop signal use the default signal
    Given I configure the system programmatically with a process that has no stop signal
    And I start the system
    When I attempt to stop the system
    Then stopping the system should not raise an error
    And the port "12414" should be closed

  Scenario: Explicit process environment overrides the parent environment
    Given the parent environment variable "STRING" is "parent"
    When I start a process runner with environment "STRING" set to "configured"
    Then the process environment output should be "configured"

  @config
  Scenario: YAML process argv commands and environment are applied
    Given I configure the system through configuration with a YAML argv process
    And I start the system
    When I send "test" with the TCP client "yaml_argv_process" to the process
    Then I should receive a TCP "test" response from the process
    And the YAML argv process shell side effect should not happen
    And the YAML process environment output should be "configured"
