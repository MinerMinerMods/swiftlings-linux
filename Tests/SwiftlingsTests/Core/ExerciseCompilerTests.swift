import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseCompilerTests {

  class MockFileManager: FileManager {
    var fileExistsResponses: [String: Bool] = [:]

    override func fileExists(atPath path: String) -> Bool {
      return fileExistsResponses[path] ?? false
    }
  }

  @Test func CompilationResultProperties() {
    let success = CompilationResult.success(output: "Compilation successful")
    #assert(success.isSuccess == true)

    let failure = CompilationResult.failure(message: "Error: undefined symbol")
    #assert(failure.isSuccess == false)
  }

  @Test func SuccessfulCompilation() throws {
    let mockRunner = MockProcessRunner()
    let mockFileManager = MockFileManager()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: mockFileManager
    )

    let exercise = Exercise(
      name: "test_exercise",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )

    let workDir = URL(fileURLWithPath: "/tmp/test")


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "Compilation successful", stderr: ""),
    ]


    mockFileManager.fileExistsResponses["/tmp/test/Assert.swift"] = false

    let result = try compiler.compile(
      exercise: exercise,
      in: workDir,
      includeAssert: true
    )


    switch result {
      case .success(let output):
        #assert(output == "Compilation successful")
      case .failure:
        Issue.record("Expected success but got failure")
    }


    #assert(mockRunner.capturedCalls.count == 1)
    let call = mockRunner.capturedCalls[0]
    #assert(call.executable == Configuration.Executables.swiftc)
    #assert(call.arguments == ["-color-diagnostics", "-o", "exercise", "main.swift", "test_exercise.swift"])
    #assert(call.directory?.path == "/tmp/test")
  }

  @Test func CompilationWithAssert() throws {
    let mockRunner = MockProcessRunner()
    let mockFileManager = MockFileManager()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: mockFileManager
    )

    let exercise = Exercise(
      name: "assert_test",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )

    let workDir = URL(fileURLWithPath: "/tmp/test")


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "Success", stderr: ""),
    ]


    mockFileManager.fileExistsResponses["/tmp/test/Assert.swift"] = true

    let result = try compiler.compile(
      exercise: exercise,
      in: workDir,
      includeAssert: true
    )

    #assert(result.isSuccess)


    let call = mockRunner.capturedCalls[0]
    #assert(call.arguments.contains("Assert.swift"))
    #assert(call.arguments == ["-color-diagnostics", "-o", "exercise", "main.swift", "assert_test.swift", "Assert.swift"])
  }

  @Test func CompilationWithoutAssertFlag() throws {
    let mockRunner = MockProcessRunner()
    let mockFileManager = MockFileManager()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: mockFileManager
    )

    let exercise = Exercise(
      name: "no_assert",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )

    let workDir = URL(fileURLWithPath: "/tmp/test")

    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "Success", stderr: ""),
    ]


    mockFileManager.fileExistsResponses["/tmp/test/Assert.swift"] = true

    let result = try compiler.compile(
      exercise: exercise,
      in: workDir,
      includeAssert: false
    )

    #assert(result.isSuccess)


    let call = mockRunner.capturedCalls[0]
    #assert(!call.arguments.contains("Assert.swift"))
  }

  @Test func CompilationFailure() throws {
    let mockRunner = MockProcessRunner()
    let mockFileManager = MockFileManager()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: mockFileManager
    )

    let exercise = Exercise(
      name: "failing_exercise",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )

    let workDir = URL(fileURLWithPath: "/tmp/test")


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "",
        stderr: "error: use of unresolved identifier 'foo'"
      ),
    ]

    let result = try compiler.compile(
      exercise: exercise,
      in: workDir,
      includeAssert: false
    )


    switch result {
      case .success:
        Issue.record("Expected failure but got success")
      case .failure(let message):
        #assert(message == "error: use of unresolved identifier 'foo'")
    }
  }

  @Test func CompilationFailureWithStdout() throws {
    let mockRunner = MockProcessRunner()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: MockFileManager()
    )

    let exercise = Exercise(
      name: "stdout_error",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )

    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "Error output in stdout",
        stderr: ""
      ),
    ]

    let result = try compiler.compile(
      exercise: exercise,
      in: URL(fileURLWithPath: "/tmp"),
      includeAssert: false
    )

    switch result {
      case .success:
        Issue.record("Expected failure")
      case .failure(let message):
        #assert(message == "Error output in stdout")
    }
  }

  @Test func CompilationWithDifferentExerciseNames() throws {
    let mockRunner = MockProcessRunner()
    let compiler = ExerciseCompiler(
      processRunner: mockRunner,
      fileManager: MockFileManager()
    )

    let exerciseNames = ["intro1", "variables_test", "complex-name", "test123"]

    for name in exerciseNames {
      mockRunner.reset()
      mockRunner.mockResults = [
        ProcessResult(exitCode: 0, stdout: "Success", stderr: ""),
      ]

      let exercise = Exercise(
        name: name,
        dir: "dir",
        hint: "hint",
        dependencies: nil
      )

      _ = try compiler.compile(
        exercise: exercise,
        in: URL(fileURLWithPath: "/tmp"),
        includeAssert: false
      )

      let call = mockRunner.capturedCalls[0]
      #assert(call.arguments.contains("\(name).swift"))
    }
  }
}
