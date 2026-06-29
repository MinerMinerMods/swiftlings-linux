import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseRunnerSimplifiedTests {
  @Test func CompilationError() {
    let error = CompilationError(message: "Failed to compile")
    #assert(error.message == "Failed to compile")
  }

  @Test func ExerciseResultProperties() {
    let success = ExerciseResult.success(output: "Test passed")
    #assert(success.isSuccess == true)

    let compilationError = ExerciseResult.compilationError(message: "Syntax error")
    #assert(compilationError.isSuccess == false)

    let testFailure = ExerciseResult.testFailure(message: "Assertion failed")
    #assert(testFailure.isSuccess == false)
  }

  @Test func ExerciseResultPatterns() {
    let results: [ExerciseResult] = [
      .success(output: "Output"),
      .compilationError(message: "Error"),
      .testFailure(message: "Failure"),
    ]

    for result in results {
      switch result {
        case .success(let output):
          #assert(result.isSuccess)
          #assert(!output.isEmpty)
        case .compilationError(let message):
          #assert(!result.isSuccess)
          #assert(!message.isEmpty)
        case .testFailure(let message):
          #assert(!result.isSuccess)
          #assert(!message.isEmpty)
      }
    }
  }
}
