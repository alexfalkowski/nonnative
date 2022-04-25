@clear
Feature: Command

  Verify commands are formatted correctly when they run.

  Scenario: Go command with parameters
    When I create the go command with output "reports" and executable "example" and command "serve" and parameters "--level=info"
    Then I should have a valid go command with output "reports" and executable "example" and command "serve" and parameters "--level=info"

  Scenario: Go command without parameters
    When I create the go command with output "reports" and executable "example" and command "serve" and parameters ""
    Then I should have a valid go command with output "reports" and executable "example" and command "serve" and parameters ""

  Scenario: Go command from configuration
    When I load the go configuration
    Then I should have a valid go command with output "reports" and executable "example" and command "serve" and parameters "--level=info"
