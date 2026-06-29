import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseResetterTests {
  @Test func ResetErrorDescriptions() {
    let gitError = ResetError.gitResetFailed("fatal: pathspec 'file.swift' did not match any files")
    #assert(gitError.errorDescription == "Failed to reset exercise: fatal: pathspec 'file.swift' did not match any files")

    let multipleErrors = ResetError.multipleErrors([
      "Failed to reset intro1: File not found",
      "Failed to reset variables1: Permission denied",
    ])
    #assert(multipleErrors.errorDescription == "Multiple reset errors:\nFailed to reset intro1: File not found\nFailed to reset variables1: Permission denied")
  }

  @Test func SuccessfulReset() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let exercise = Exercise(
      name: "test_exercise",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
    ]

    try resetter.resetExercise(exercise)


    #assert(mockRunner.capturedCalls.count == 1)
    let call = mockRunner.capturedCalls[0]
    #assert(call.executable == Configuration.Executables.git)
    #assert(call.arguments == ["checkout", "HEAD", "--", "exercises/test_dir/test_exercise.swift"])
    #assert(call.directory == nil)
  }

  @Test func GitResetFailure() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let exercise = Exercise(
      name: "failing_exercise",
      dir: "test_dir",
      hint: "Test hint",
      dependencies: nil
    )


    mockRunner.mockResults = [
      ProcessResult(
        exitCode: 1,
        stdout: "",
        stderr: "error: pathspec 'exercises/test_dir/failing_exercise.swift' did not match any file(s) known to git"
      ),
    ]
    #assert(throws: (any Error).self) { _ = try resetter.resetExercise(exercise) }
  }

  @Test func ResetMultipleExercisesSuccess() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let exercises = [
      Exercise(name: "ex1", dir: "dir1", hint: "hint1", dependencies: nil),
      Exercise(name: "ex2", dir: "dir2", hint: "hint2", dependencies: nil),
      Exercise(name: "ex3", dir: "dir3", hint: "hint3", dependencies: nil),
    ]


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
    ]

    try resetter.resetExercises(exercises)


    #assert(mockRunner.capturedCalls.count == 3)
    #assert(mockRunner.capturedCalls[0].arguments.contains("exercises/dir1/ex1.swift"))
    #assert(mockRunner.capturedCalls[1].arguments.contains("exercises/dir2/ex2.swift"))
    #assert(mockRunner.capturedCalls[2].arguments.contains("exercises/dir3/ex3.swift"))
  }

  @Test func ResetMultipleExercisesWithFailures() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let exercises = [
      Exercise(name: "ex1", dir: "dir1", hint: "hint1", dependencies: nil),
      Exercise(name: "ex2", dir: "dir2", hint: "hint2", dependencies: nil),
      Exercise(name: "ex3", dir: "dir3", hint: "hint3", dependencies: nil),
    ]


    mockRunner.mockResults = [
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
      ProcessResult(exitCode: 1, stdout: "", stderr: "Permission denied"),
      ProcessResult(exitCode: 0, stdout: "", stderr: ""),
    ]
    #assert(throws: (any Error).self, "ExerciseResetter doesn't alert") { _ = try resetter.resetExercises(exercises) }

    #assert(mockRunner.capturedCalls.count == 3)
  }

  @Test func ResetEmptyList() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)


    try resetter.resetExercises([])


    #assert(mockRunner.capturedCalls.isEmpty)
  }

  @Test func ResetWithDifferentPaths() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let testCases = [
      (name: "simple", dir: "basics", expected: "exercises/basics/simple.swift"),
      (name: "complex_name", dir: "advanced/nested", expected: "exercises/advanced/nested/complex_name.swift"),
      (name: "test-123", dir: "00_intro", expected: "exercises/00_intro/test-123.swift"),
    ]

    for testCase in testCases {
      mockRunner.reset()
      mockRunner.mockResults = [
        ProcessResult(exitCode: 0, stdout: "", stderr: ""),
      ]

      let exercise = Exercise(
        name: testCase.name,
        dir: testCase.dir,
        hint: "hint",
        dependencies: nil
      )

      try resetter.resetExercise(exercise)

      let call = mockRunner.capturedCalls[0]
      #assert(call.arguments.last == testCase.expected)
    }
  }

  @Test func MultipleErrorsFormatting() throws {
    let mockRunner = MockProcessRunner()
    let resetter = ExerciseResetter(processRunner: mockRunner)

    let exercises = [
      Exercise(name: "ex1", dir: "dir1", hint: "hint1", dependencies: nil),
      Exercise(name: "ex2", dir: "dir2", hint: "hint2", dependencies: nil),
      Exercise(name: "ex3", dir: "dir3", hint: "hint3", dependencies: nil),
    ]


    mockRunner.mockResults = [
      ProcessResult(exitCode: 1, stdout: "", stderr: "Error 1"),
      ProcessResult(exitCode: 1, stdout: "", stderr: "Error 2"),
      ProcessResult(exitCode: 1, stdout: "", stderr: "Error 3"),
    ]

    #assert(try? resetter.resetExercises(exercises) != nil)
  }
}
