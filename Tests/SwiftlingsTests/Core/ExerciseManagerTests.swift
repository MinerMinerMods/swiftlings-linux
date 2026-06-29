import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct ExerciseManagerTests {
  class MockProgressTracker: ProgressTracker {
    var completedExercises: Set<String> = []
    var currentExercise: String?

    override func isCompleted(_ exerciseName: String) -> Bool {
      completedExercises.contains(exerciseName)
    }

    override func markCompleted(_ exerciseName: String) {
      completedExercises.insert(exerciseName)
    }

    override func getCurrentExercise() -> String? {
      currentExercise
    }

    override func setCurrentExercise(_ exerciseName: String) {
      currentExercise = exerciseName
    }

    override func getStats(totalExercises: Int) -> (completed: Int, percentage: Double) {
      let completed = completedExercises.count
      let percentage = totalExercises > 0 ? Double(completed) / Double(totalExercises) * 100 : 0
      return (completed, percentage)
    }

    override func resetProgress() {
      completedExercises.removeAll()
      currentExercise = nil
    }
  }


  func createTestMetadata() -> ExerciseMetadata {
    let exercises = [
      Exercise(name: "intro1", dir: "00_basics", hint: "Intro hint", dependencies: nil),
      Exercise(name: "intro2", dir: "00_basics", hint: "Intro hint 2", dependencies: nil),
      Exercise(name: "variables1", dir: "01_variables", hint: "Variables hint", dependencies: ["Foundation"]),
      Exercise(name: "variables2", dir: "01_variables", hint: "Variables hint 2", dependencies: ["Foundation"]),
      Exercise(name: "functions1", dir: "02_functions", hint: "Functions hint", dependencies: nil),
    ]

    return ExerciseMetadata(
      formatVersion: 1,
      welcomeMessage: "Welcome to testing!",
      finalMessage: "Congratulations on testing!",
      exercises: exercises
    )
  }

  @Test func ExerciseManagerWithTestData() throws {

    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    defer {
      try? FileManager.default.removeItem(at: tempDir)
    }

    let metadata = createTestMetadata()
    let encoder = JSONEncoder()
    let data = try encoder.encode(metadata)


    let exercisesDir = tempDir.appendingPathComponent("exercises")
    try FileManager.default.createDirectory(at: exercisesDir, withIntermediateDirectories: true)


    try data.write(to: exercisesDir.appendingPathComponent("info.json"))


    let originalDir = FileManager.default.currentDirectoryPath
    FileManager.default.changeCurrentDirectoryPath(tempDir.path)
    defer {
      FileManager.default.changeCurrentDirectoryPath(originalDir)
    }


    let manager = try ExerciseManager()

    #assert(manager.allExercises.count == 5)
    #assert(manager.welcomeMessage == "Welcome to testing!")
    #assert(manager.finalMessage == "Congratulations on testing!")
  }

  @Test func GetAllExercises() throws {


    _ = MockProgressTracker()


    let exercises = [
      Exercise(name: "ex1", dir: "dir1", hint: "hint1", dependencies: nil),
      Exercise(name: "ex2", dir: "dir2", hint: "hint2", dependencies: nil),
    ]



    #assert(exercises.count == 2)
    #assert(exercises[0].name == "ex1")
    #assert(exercises[1].name == "ex2")
  }

  @Test func GetExerciseByName() {
    let exercises = [
      Exercise(name: "target", dir: "dir", hint: "hint", dependencies: nil),
      Exercise(name: "other", dir: "dir", hint: "hint", dependencies: nil),
    ]


    let found = exercises.first { $0.name == "target" }
    #assert(found?.name == "target")

    let notFound = exercises.first { $0.name == "nonexistent" }
    #assert(notFound == nil)
  }

  @Test func ProgressTracking() {
    let tracker = MockProgressTracker()
    let exercises = createTestMetadata().exercises


    #assert(!tracker.isCompleted("intro1"))
    #assert(!tracker.isCompleted("variables1"))


    tracker.markCompleted("intro1")
    tracker.markCompleted("variables1")

    #assert(tracker.isCompleted("intro1"))
    #assert(tracker.isCompleted("variables1"))
    #assert(!tracker.isCompleted("intro2"))


    let completed = exercises.filter { tracker.isCompleted($0.name) }
    let pending = exercises.filter { !tracker.isCompleted($0.name) }

    #assert(completed.count == 2)
    #assert(pending.count == 3)
  }

  @Test func GetNextPendingExercise() {
    let tracker = MockProgressTracker()
    let exercises = createTestMetadata().exercises


    let firstPending = exercises.first { !tracker.isCompleted($0.name) }
    #assert(firstPending?.name == "intro1")


    tracker.markCompleted("intro1")
    tracker.markCompleted("intro2")

    let nextPending = exercises.first { !tracker.isCompleted($0.name) }
    #assert(nextPending?.name == "variables1")


    for exercise in exercises {
      tracker.markCompleted(exercise.name)
    }

    let noPending = exercises.first { !tracker.isCompleted($0.name) }
    #assert(noPending == nil)
  }

  @Test func ExerciseStatus() {
    let tracker = MockProgressTracker()


    let completedStatus = tracker.isCompleted("test") ? "✅" : "❌"
    #assert(completedStatus == "❌")

    tracker.markCompleted("test")
    let newStatus = tracker.isCompleted("test") ? "✅" : "❌"
    #assert(newStatus == "✅")
  }

  @Test func ProgressStatistics() {
    let tracker = MockProgressTracker()
    let totalExercises = 10


    var stats = tracker.getStats(totalExercises: totalExercises)
    #assert(stats.completed == 0)
    #assert(stats.percentage == 0.0)


    tracker.markCompleted("ex1")
    tracker.markCompleted("ex2")
    tracker.markCompleted("ex3")

    stats = tracker.getStats(totalExercises: totalExercises)
    #assert(stats.completed == 3)
    #assert(stats.percentage == 30.0)


    for i in 1 ... 10 {
      tracker.markCompleted("ex\(i)")
    }

    stats = tracker.getStats(totalExercises: totalExercises)
    #assert(stats.completed == 10)
    #assert(stats.percentage == 100.0)
  }

  @Test func CurrentExercise() {
    let tracker = MockProgressTracker()
    let exercises = createTestMetadata().exercises


    #assert(tracker.getCurrentExercise() == nil)


    tracker.setCurrentExercise("variables1")
    #assert(tracker.getCurrentExercise() == "variables1")


    if let currentName = tracker.getCurrentExercise() {
      let current = exercises.first { $0.name == currentName }
      #assert(current?.name == "variables1")
    }


    tracker.currentExercise = nil
    tracker.markCompleted("intro1")

    let firstPending = exercises.first { !tracker.isCompleted($0.name) }
    #assert(firstPending?.name == "intro2")
  }

  @Test func ResetAllProgress() {
    let tracker = MockProgressTracker()


    tracker.markCompleted("ex1")
    tracker.markCompleted("ex2")
    tracker.setCurrentExercise("ex3")

    #assert(tracker.completedExercises.count == 2)
    #assert(tracker.currentExercise == "ex3")


    tracker.resetProgress()

    #assert(tracker.completedExercises.isEmpty)
    #assert(tracker.currentExercise == nil)
  }
}
