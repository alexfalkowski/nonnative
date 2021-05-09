Feature: Command

  Verify commands are formatted correctly when they run.

  Scenario: Go command with parameters
    When I create the go command with output "reports" and executable "example" and command "serve" and parameters "--level=info"
    Then the go command should be "example -test.cpuprofile=reports/example-serve-levelinfo-cpu.prof -test.memprofile=reports/example-serve-levelinfo-mem.prof -test.blockprofile=reports/example-serve-levelinfo-block.prof -test.mutexprofile=reports/example-serve-levelinfo-mutex.prof -test.coverprofile=reports/example-serve-levelinfo.cov -test.trace=reports/example-serve-levelinfo-trace.out serve --level=info"

  Scenario: Go command without parameters
    When I create the go command with output "reports" and executable "example" and command "serve" and parameters ""
    Then the go command should be "example -test.cpuprofile=reports/example-serve-cpu.prof -test.memprofile=reports/example-serve-mem.prof -test.blockprofile=reports/example-serve-block.prof -test.mutexprofile=reports/example-serve-mutex.prof -test.coverprofile=reports/example-serve.cov -test.trace=reports/example-serve-trace.out serve"

  Scenario: Go command from configuration
    When I load the go configuration
    Then the go command should be "example -test.cpuprofile=reports/example-serve-levelinfo-cpu.prof -test.memprofile=reports/example-serve-levelinfo-mem.prof -test.blockprofile=reports/example-serve-levelinfo-block.prof -test.mutexprofile=reports/example-serve-levelinfo-mutex.prof -test.coverprofile=reports/example-serve-levelinfo.cov -test.trace=reports/example-serve-levelinfo-trace.out serve --level=info"
