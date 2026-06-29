import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ProcessRunnerTests {
  @Test func ProcessResultProperties() {
    let successResult = ProcessResult(
      exitCode: 0,
      stdout: "Success output",
      stderr: ""
    )
    #assert(successResult.isSuccess == true)
    #assert(successResult.exitCode == 0)
    #assert(successResult.stdout == "Success output")
    #assert(successResult.stderr.isEmpty)

    let failureResult = ProcessResult(
      exitCode: 1,
      stdout: "",
      stderr: "Error occurred"
    )
    #assert(failureResult.isSuccess == false)
    #assert(failureResult.exitCode == 1)
    #assert(failureResult.stdout.isEmpty)
    #assert(failureResult.stderr == "Error occurred")
  }

  @Test func ProcessRunnerEcho() throws {
    let runner = ProcessRunner()
    let result = try runner.run(
      executable: "/bin/echo",
      arguments: ["Hello, World!"],
      currentDirectory: nil
    )

    #assert(result.isSuccess)
    #assert(result.exitCode == 0)
    #assert(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello, World!")
    #assert(result.stderr.isEmpty)
  }

  @Test func ProcessRunnerWithDirectory() throws {
    let runner = ProcessRunner()
    let tempDir = FileManager.default.temporaryDirectory

    let result = try runner.run(
      executable: "/bin/pwd",
      arguments: [],
      currentDirectory: tempDir
    )

    #assert(result.isSuccess)

    let outputPath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let expectedPath = tempDir.path
    #assert(outputPath.hasSuffix(expectedPath.split(separator: "/").suffix(3).joined(separator: "/")) || outputPath == expectedPath)
  }

  @Test func ProcessRunnerFailure() throws {
    let runner = ProcessRunner()
    let result = try runner.run(
      executable: "/bin/ls",
      arguments: ["/nonexistent/directory/that/should/not/exist"],
      currentDirectory: nil
    )

    #assert(!result.isSuccess)
    #assert(result.exitCode != 0)
    #assert(!result.stderr.isEmpty)
  }

  @Test func ProcessRunnerSwift() throws {
    let runner = ProcessRunner()
    let result = try runner.run(
      executable: Configuration.Executables.swiftc,
      arguments: ["--version"],
      currentDirectory: nil
    )

    #assert(result.isSuccess)
    #assert(result.stdout.contains("Swift") || result.stderr.contains("Swift"))
  }

  @Test func `Validate MockProcessRunner`() throws {
    let mock = MockProcessRunner()


    mock.mockResults = [
      ProcessResult(exitCode: 0, stdout: "First result", stderr: ""),
      ProcessResult(exitCode: 1, stdout: "", stderr: "Second error"),
    ]


    let result1 = try mock.run(
      executable: "/bin/test",
      arguments: ["arg1", "arg2"],
      currentDirectory: nil
    )

    #assert(result1.exitCode == 0)
    #assert(result1.stdout == "First result")
    #assert(result1.stderr.isEmpty)


    let result2 = try mock.run(
      executable: "/bin/test2",
      arguments: ["arg3"],
      currentDirectory: URL(fileURLWithPath: "/tmp")
    )

    #assert(result2.exitCode == 1)
    #assert(result2.stdout.isEmpty)
    #assert(result2.stderr == "Second error")


    #assert(mock.capturedCalls.count == 2)
    #assert(mock.capturedCalls[0].executable == "/bin/test")
    #assert(mock.capturedCalls[0].arguments == ["arg1", "arg2"])
    #assert(mock.capturedCalls[0].directory == nil)
    #assert(mock.capturedCalls[1].executable == "/bin/test2")
    #assert(mock.capturedCalls[1].arguments == ["arg3"])
    #assert(mock.capturedCalls[1].directory?.path == "/tmp")
  }

  @Test func MockProcessRunnerDefault() throws {
    let mock = MockProcessRunner()

    let result = try mock.run(
      executable: "/bin/test",
      arguments: [],
      currentDirectory: nil
    )

    #assert(result.exitCode == 0)
    #assert(result.stdout.isEmpty)
    #assert(result.stderr.isEmpty)
  }

  @Test func `MockProcessRunner Resettable`() throws {
    let mock = MockProcessRunner()

    mock.mockResults = [ProcessResult(exitCode: 42, stdout: "Test", stderr: "")]

    _ = try mock.run(executable: "/bin/test", arguments: [], currentDirectory: nil)
    #assert(mock.capturedCalls.count == 1)

    mock.reset()

    #assert(mock.capturedCalls.isEmpty)


    let result = try mock.run(executable: "/bin/test", arguments: [], currentDirectory: nil)
    #assert(result.exitCode == 42)
  }

  @Test func `ProcessRunner supports multiple arguments`() throws {
    let runner = ProcessRunner()
    let result = try runner.run(
      executable: "/bin/echo",
      arguments: ["-n", "arg1", "arg2", "arg3"],
      currentDirectory: nil
    )

    #assert(result.isSuccess)
    #assert(result.stdout == "arg1 arg2 arg3")
  }
}
