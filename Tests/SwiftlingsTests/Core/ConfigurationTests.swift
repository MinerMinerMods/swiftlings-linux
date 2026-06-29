import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
extension Tag {
  @Tag static var configuration: Self
}

@available(macOS,10_15)
@Suite("Configuration Tests")
struct ConfigurationTests {
  @Test
  func ExecutablePaths() {
    // Resolved from PATH, so the directory varies by toolchain. Check that we
    // got an absolute path to the right tool rather than a fixed location.
    #assert(Configuration.Executables.git.hasPrefix("/"))
    #assert(Configuration.Executables.git.hasSuffix("git"))
    #assert(Configuration.Executables.swiftc.hasPrefix("/"))
    #assert(Configuration.Executables.swiftc.hasSuffix("swiftc"))
  }

  @Test
  func FilePaths() {
    #assert(Configuration.Paths.stateFileName == ".swiftlings-state.json")
    #assert(Configuration.Paths.exerciseInfoFile == "exercises/info.json")
    #assert(Configuration.Paths.assertSourcePath == "Sources/Swiftlings/Core/Assert.swift")
  }

  @Test
  func UIConfiguration() {
    #assert(Configuration.UI.progressBarWidth == 120)
    #assert(Configuration.UI.defaultTerminalWidth == 80)
  }

  @Test
  func ExerciseConfiguration() {
    #assert(Configuration.Exercise.tempDirectoryPrefix == "swiftlings")
    #assert(Configuration.Exercise.compiledExecutableName == "exercise")
    #assert(Configuration.Exercise.mainFileName == "main.swift")
  }

  @Test
  func ConfigurationValuesAreReasonable() {

    #assert(Configuration.Executables.git.hasPrefix("/"))
    #assert(Configuration.Executables.swiftc.hasPrefix("/"))


    #assert(Configuration.UI.progressBarWidth > 0)
    #assert(Configuration.UI.defaultTerminalWidth > 0)


    #assert(!Configuration.Paths.stateFileName.isEmpty)
    #assert(!Configuration.Paths.exerciseInfoFile.isEmpty)
    #assert(!Configuration.Paths.assertSourcePath.isEmpty)


    #assert(!Configuration.Exercise.tempDirectoryPrefix.isEmpty)
    #assert(!Configuration.Exercise.compiledExecutableName.isEmpty)
    #assert(!Configuration.Exercise.mainFileName.isEmpty)


    #assert(Configuration.Paths.stateFileName.hasPrefix("."))


    #assert(Configuration.Exercise.mainFileName.hasSuffix(".swift"))
  }

  @Test
  func PathConsistency() {

    #assert(Configuration.Paths.assertSourcePath.hasSuffix("Assert.swift"))


    #assert(Configuration.Paths.exerciseInfoFile.hasPrefix("exercises/"))


    #assert(Configuration.Paths.exerciseInfoFile.hasSuffix(".json"))
  }
}
