import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ProgressTrackerTests {

  func withTemporaryDirectory(_ test: (URL) throws -> Void) throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let originalDir = FileManager.default.currentDirectoryPath
    FileManager.default.changeCurrentDirectoryPath(tempDir.path)

    defer {
      FileManager.default.changeCurrentDirectoryPath(originalDir)
      try? FileManager.default.removeItem(at: tempDir)
    }

    try test(tempDir)
  }

  @Test func InitializationWithNoState() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()

      #assert(tracker.getCurrentExercise() == nil)
      #assert(!tracker.isCompleted("any_exercise"))

      let stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 0)
      #assert(stats.percentage == 0.0)
    }
  }

  @Test func MarkCompleted() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()

      #assert(!tracker.isCompleted("variables1"))

      tracker.markCompleted("variables1")

      #assert(tracker.isCompleted("variables1"))
      #assert(!tracker.isCompleted("variables2"))
    }
  }

  @Test func CurrentExercise() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()

      #assert(tracker.getCurrentExercise() == nil)

      tracker.setCurrentExercise("functions1")
      #assert(tracker.getCurrentExercise() == "functions1")

      tracker.setCurrentExercise("functions2")
      #assert(tracker.getCurrentExercise() == "functions2")
    }
  }

  @Test func ProgressStatistics() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()


      var stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 0)
      #assert(stats.percentage == 0.0)


      tracker.markCompleted("ex1")
      tracker.markCompleted("ex2")
      tracker.markCompleted("ex3")

      stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 3)
      #assert(stats.percentage == 30.0)


      for i in 4 ... 10 {
        tracker.markCompleted("ex\(i)")
      }

      stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 10)
      #assert(stats.percentage == 100.0)


      stats = tracker.getStats(totalExercises: 0)
      #assert(stats.completed == 10)
      #assert(stats.percentage == 0.0)
    }
  }

  @Test func ResetProgress() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()


      tracker.markCompleted("ex1")
      tracker.markCompleted("ex2")
      tracker.setCurrentExercise("ex3")

      #assert(tracker.isCompleted("ex1"))
      #assert(tracker.isCompleted("ex2"))
      #assert(tracker.getCurrentExercise() == "ex3")


      tracker.resetProgress()

      #assert(!tracker.isCompleted("ex1"))
      #assert(!tracker.isCompleted("ex2"))
      #assert(tracker.getCurrentExercise() == nil)

      let stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 0)
      #assert(stats.percentage == 0.0)
    }
  }

  @Test func StatePersistence() throws {
    try withTemporaryDirectory { tempDir in

      let stateFile = tempDir.appendingPathComponent(".swiftlings-state.json")


      var state1 = ProgressTracker.ProgressState()
      state1.completedExercises.insert("persistent1")
      state1.completedExercises.insert("persistent2")
      state1.currentExercise = "persistent3"

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(state1)
      try data.write(to: stateFile)





      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let loadedState = try decoder.decode(ProgressTracker.ProgressState.self, from: data)

      #assert(loadedState.completedExercises.contains("persistent1"))
      #assert(loadedState.completedExercises.contains("persistent2"))
      #assert(loadedState.currentExercise == "persistent3")
    }
  }

  @Test func MultipleCompletions() throws {
    try withTemporaryDirectory { _ in
      let tracker = ProgressTracker()
      let exercises = ["intro1", "variables1", "functions1", "arrays1", "structs1"]

      for exercise in exercises {
        #assert(!tracker.isCompleted(exercise))
        tracker.markCompleted(exercise)
        #assert(tracker.isCompleted(exercise))
      }

      let stats = tracker.getStats(totalExercises: 10)
      #assert(stats.completed == 5)
      #assert(stats.percentage == 50.0)


      tracker.markCompleted("intro1")
      tracker.markCompleted("intro1")

      let statsAfter = tracker.getStats(totalExercises: 10)
      #assert(statsAfter.completed == 5)
    }
  }

  @Test func StateFileFormat() throws {


    var state = ProgressTracker.ProgressState()
    state.completedExercises.insert("test1")
    state.currentExercise = "test2"
    state.lastUpdated = Date()

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(state)

    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #assert(json != nil)
    #assert(json?["currentExercise"] as? String == "test2")
    #assert((json?["completedExercises"] as? [String])?.contains("test1") == true)
    #assert(json?["lastUpdated"] != nil)
  }
}
