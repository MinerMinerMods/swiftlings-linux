import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseTests {
  @Test func ExerciseInitialization() {
    let exercise = Exercise(
      name: "variables1",
      dir: "01_variables",
      hint: "This is a hint",
      dependencies: ["Foundation"]
    )

    #assert(exercise.name == "variables1")
    #assert(exercise.dir == "01_variables")
    #assert(exercise.hint == "This is a hint")
    #assert(exercise.dependencies == ["Foundation"])
    #assert(exercise.filePath == "exercises/01_variables/variables1.swift")
  }

  @Test func ExerciseWithoutDependencies() {
    let exercise = Exercise(
      name: "intro1",
      dir: "00_basics",
      hint: "Simple intro",
      dependencies: nil
    )

    #assert(exercise.dependencies == nil)
  }

  @Test func FilePathConstruction() {
    let testCases = [
      (name: "test1", dir: "00_basics", expected: "exercises/00_basics/test1.swift"),
      (name: "functions1", dir: "02_functions", expected: "exercises/02_functions/functions1.swift"),
      (name: "complex_name", dir: "deep/nested/dir", expected: "exercises/deep/nested/dir/complex_name.swift"),
    ]

    for testCase in testCases {
      let exercise = Exercise(
        name: testCase.name,
        dir: testCase.dir,
        hint: "",
        dependencies: nil
      )
      #assert(exercise.filePath == testCase.expected)
    }
  }

  @Test func ExerciseEquality() {
    let exercise1 = Exercise(
      name: "test",
      dir: "dir",
      hint: "hint",
      dependencies: ["A", "B"]
    )

    let exercise2 = Exercise(
      name: "test",
      dir: "dir",
      hint: "hint",
      dependencies: ["A", "B"]
    )

    let exercise3 = Exercise(
      name: "different",
      dir: "dir",
      hint: "hint",
      dependencies: ["A", "B"]
    )

    #assert(exercise1 == exercise2)
    #assert(exercise1 != exercise3)
  }

  @Test func ExerciseCodable() throws {
    let original = Exercise(
      name: "codable_test",
      dir: "test_dir",
      hint: "Test hint with special chars: 🎯 \"quotes\" and 'apostrophes'",
      dependencies: ["Foundation", "UIKit"]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Exercise.self, from: data)

    #assert(decoded == original)
    #assert(decoded.name == original.name)
    #assert(decoded.dir == original.dir)
    #assert(decoded.hint == original.hint)
    #assert(decoded.dependencies == original.dependencies)
  }
}
