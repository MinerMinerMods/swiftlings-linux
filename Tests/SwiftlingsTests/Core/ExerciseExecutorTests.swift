import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseExecutorTests {
  @Test func SuccessfulExecutionWithoutTests() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "Hello, World!", stderr: ""),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: false
    )


    switch result {
      case .success(let output):
        #assert(output == "Hello, World!")
      case .testFailure:
        Issue.record("Expected success but got test failure")
    }


    #assert(mockRunner.capturedCalls.count == 1)
    let call = mockRunner.capturedCalls[0]
    #assert(call.executable == "/tmp/test/exercise")
    #assert(call.arguments.isEmpty)
    #assert(call.directory?.path == "/tmp/test")
  }

  @Test func SuccessfulExecutionWithTests() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "All tests passed!", stderr: ""),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: true
    )

    switch result {
      case .success(let output):
        #assert(output == "All tests passed!")
      case .testFailure:
        Issue.record("Expected success but got test failure")
    }
  }

  @Test func ExecutionWithTestFailure() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "Test 1: Passed\nTest 2: Failed",
        stderr: "Assertion failed"
      ),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: true
    )

    switch result {
      case .success:
        Issue.record("Expected test failure but got success")
      case .testFailure(let message):
        #assert(message == "Test 1: Passed\nTest 2: Failed\nAssertion failed")
    }
  }

  @Test func ExecutionFailureWithoutTests() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "",
        stderr: "Segmentation fault"
      ),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: false
    )

    switch result {
      case .success:
        Issue.record("Expected failure but got success")
      case .testFailure(let message):
        #assert(message == "Segmentation fault")
    }
  }

  @Test func ExecutionFailureWithoutStderr() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 42,
        stdout: "",
        stderr: ""
      ),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: false
    )

    switch result {
      case .success:
        Issue.record("Expected failure but got success")
      case .testFailure(let message):
        #assert(message == "Exercise failed with exit code 42")
    }
  }

  @Test func ExecutionWithDifferentPaths() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let testPaths = [
      "/tmp/exercise",
      "/usr/local/bin/test",
      "/home/user/swiftlings/exercise",
      "/tmp/dir with spaces/exercise",
    ]

    for path in testPaths {
      mockRunner.reset()
      mockRunner.mockResults = [
        ProcessResult(exitCode: 0, stdout: "Success", stderr: ""),
      ]

      let url = URL(fileURLWithPath: path)
      _ = try executor.execute(executablePath: url, usesTests: false)

      let call = mockRunner.capturedCalls[0]
      #assert(call.executable == path)
      #assert(call.directory?.path == url.deletingLastPathComponent().path)
    }
  }

  @Test func ExecutionWithEmptyStdoutTestMode() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "",
        stderr: "Test assertion failed at line 10"
      ),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: true
    )

    switch result {
      case .success:
        Issue.record("Expected test failure")
      case .testFailure(let message):
        #assert(message == "\nTest assertion failed at line 10")
    }
  }

  @Test func ExecutionWithCombinedOutput() throws {
    let mockRunner = MockProcessRunner()
    let executor = ExerciseExecutor(processRunner: mockRunner)

    let executablePath = URL(fileURLWithPath: "/tmp/test/exercise")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "Running tests...\nTest 1: OK",
        stderr: "Fatal error: Test 2 failed"
      ),
    ]

    let result = try executor.execute(
      executablePath: executablePath,
      usesTests: true
    )

    switch result {
      case .success:
        Issue.record("Expected test failure")
      case .testFailure(let message):
        #assert(message == "Running tests...\nTest 1: OK\nFatal error: Test 2 failed")
    }
  }
}
