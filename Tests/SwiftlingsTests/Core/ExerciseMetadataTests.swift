import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseMetadataTests {
  @Test func ExerciseMetadataInitialization() {
    let exercises = [
      Exercise(name: "intro1", dir: "00_basics", hint: "Intro hint", dependencies: nil),
      Exercise(name: "variables1", dir: "01_variables", hint: "Variables hint", dependencies: ["Foundation"]),
    ]

    let metadata = ExerciseMetadata(
      formatVersion: 1,
      welcomeMessage: "Welcome to Swiftlings!",
      finalMessage: "Congratulations!",
      exercises: exercises
    )

    #assert(metadata.formatVersion == 1)
    #assert(metadata.welcomeMessage == "Welcome to Swiftlings!")
    #assert(metadata.finalMessage == "Congratulations!")
    #assert(metadata.exercises.count == 2)
    #assert(metadata.exercises[0].name == "intro1")
    #assert(metadata.exercises[1].name == "variables1")
  }

  @Test func ExerciseMetadataCodable() throws {
    let exercises = [
      Exercise(name: "test1", dir: "test", hint: "Hint 1", dependencies: nil),
      Exercise(name: "test2", dir: "test", hint: "Hint 2", dependencies: ["Foundation", "UIKit"]),
    ]

    let original = ExerciseMetadata(
      formatVersion: 2,
      welcomeMessage: "Welcome message with special chars: 🎯 \"quotes\"",
      finalMessage: "Final message with newline\nand more text",
      exercises: exercises
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ExerciseMetadata.self, from: data)

    #assert(decoded.formatVersion == original.formatVersion)
    #assert(decoded.welcomeMessage == original.welcomeMessage)
    #assert(decoded.finalMessage == original.finalMessage)
    #assert(decoded.exercises.count == original.exercises.count)
    #assert(decoded.exercises == original.exercises)
  }

  @Test func JSONKeyMapping() throws {
    let jsonString = """
                     {
                       "format_version": 3,
                       "welcome_message": "Test welcome",
                       "final_message": "Test final",
                       "exercises": [
                         {
                           "name": "exercise1",
                           "dir": "dir1",
                           "hint": "hint1"
                         }
                       ]
                     }
                     """

    let data = jsonString.data(using: .utf8) !
    let decoder = JSONDecoder()
    let metadata = try decoder.decode(ExerciseMetadata.self, from: data)

    #assert(metadata.formatVersion == 3)
    #assert(metadata.welcomeMessage == "Test welcome")
    #assert(metadata.finalMessage == "Test final")
    #assert(metadata.exercises.count == 1)
  }

  @Test func LoadFromFile() throws {

    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("test_info.json")

    let testMetadata = ExerciseMetadata(
      formatVersion: 1,
      welcomeMessage: "Welcome from file",
      finalMessage: "Final from file",
      exercises: [
        Exercise(name: "file_test", dir: "test_dir", hint: "File test hint", dependencies: nil),
      ]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(testMetadata)
    try data.write(to: tempFile)

    defer {
      try ? FileManager.default.removeItem(at: tempFile)
    }


    let loaded = try ExerciseMetadata.load(from: tempFile.path)

    #assert(loaded.formatVersion == 1)
    #assert(loaded.welcomeMessage == "Welcome from file")
    #assert(loaded.finalMessage == "Final from file")
    #assert(loaded.exercises.count == 1)
    #assert(loaded.exercises[0].name == "file_test")
  }

  @Test func LoadFromMissingFile() {
    #assert(throws: (any Error).self, "Expected an error when loading from a nonexistent file path") {
      _ = try ExerciseMetadata.load(from: "/nonexistent/path/info.json")
    }
  }

  @Test func EmptyExercises() throws {
    let metadata = ExerciseMetadata(
      formatVersion: 1,
      welcomeMessage: "Welcome",
      finalMessage: "Final",
      exercises: []
    )

    #assert(metadata.exercises.isEmpty)


    let encoder = JSONEncoder()
    let data = try encoder.encode(metadata)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ExerciseMetadata.self, from: data)

    #assert(decoded.exercises.isEmpty)
  }

  @Test func MalformedJSON() {
    let malformedJSON = """
                        {
                          "format_version": "not a number",
                          "welcome_message": "Test",
                          "final_message": "Test",
                          "exercises": []
                        }
                        """

    let data = malformedJSON.data(using: .utf8) !
    let decoder = JSONDecoder()

    #assert(throws: (any Error).self, "Expected an error when decoding malformed JSON") {
      _ = try decoder.decode(ExerciseMetadata.self, from: data)
    }
  }
}