import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct SwiftlingsErrorTests {
  @Test func SwiftlingsErrorProtocol() {
    let error: SwiftlingsError = ExerciseError.notFound(name: "test")
    #assert(error.errorDescription == "Exercise 'test' not found")
    #assert(error.userMessage == "Exercise 'test' not found")
  }

  @Test func ExerciseError() {

    let notFound = ExerciseError.notFound(name: "variables1")
    #assert(notFound.userMessage == "Exercise 'variables1' not found")


    let compilationFailed = ExerciseError.compilationFailed(
      message: "error: use of unresolved identifier 'foo'"
    )
    #assert(compilationFailed.userMessage == "Compilation failed:\nerror: use of unresolved identifier 'foo'")


    let testsFailed = ExerciseError.testsFailed(
      message: "Test case 'testAddition' failed: Expected 4 but got 5"
    )
    #assert(testsFailed.userMessage == "Tests failed:\nTest case 'testAddition' failed: Expected 4 but got 5")


    let executionFailed = ExerciseError.executionFailed(exitCode: 127)
    #assert(executionFailed.userMessage == "Exercise failed with exit code 127")


    let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Permission denied",
    ])
    let fileReadError = ExerciseError.fileReadError(
      path: "/path/to/file.swift",
      underlying: underlyingError
    )
    #assert(fileReadError.userMessage == "Failed to read file '/path/to/file.swift': Permission denied")
  }

  @Test func ProgressError() {
    let underlyingError = NSError(domain: "TestDomain", code: 2, userInfo: [
      NSLocalizedDescriptionKey: "File not found",
    ])


    let failedToLoad = ProgressError.failedToLoad(underlying: underlyingError)
    #assert(failedToLoad.userMessage == "Failed to load progress: File not found")


    let failedToSave = ProgressError.failedToSave(underlying: underlyingError)
    #assert(failedToSave.userMessage == "Failed to save progress: File not found")


    let corrupted = ProgressError.corrupted(message: "Invalid JSON structure")
    #assert(corrupted.userMessage == "Progress file corrupted: Invalid JSON structure")
  }

  @Test func ProcessError() {

    let execNotFound = ProcessError.executableNotFound(path: "/usr/bin/nonexistent")
    #assert(execNotFound.userMessage == "Executable not found: /usr/bin/nonexistent")


    let execFailed = ProcessError.executionFailed(
      executable: "swiftc",
      exitCode: 1,
      stderr: "error: module 'Foundation' not found"
    )
    #assert(execFailed.userMessage == "swiftc failed (exit code 1):\nerror: module 'Foundation' not found")


    let timeout = ProcessError.timeout(executable: "swift")
    #assert(timeout.userMessage == "swift timed out")
  }

  @Test func FileSystemError() {

    let fileNotFound = FileSystemError.fileNotFound(path: "/path/to/missing.swift")
    #assert(fileNotFound.userMessage == "File not found: /path/to/missing.swift")


    let dirNotFound = FileSystemError.directoryNotFound(path: "/missing/directory")
    #assert(dirNotFound.userMessage == "Directory not found: /missing/directory")


    let permDenied = FileSystemError.permissionDenied(path: "/root/protected.file")
    #assert(permDenied.userMessage == "Permission denied: /root/protected.file")


    let createError = NSError(domain: "TestDomain", code: 3, userInfo: [
      NSLocalizedDescriptionKey: "Disk full",
    ])
    let failedCreate = FileSystemError.failedToCreateDirectory(
      path: "/new/dir",
      underlying: createError
    )
    #assert(failedCreate.userMessage == "Failed to create directory '/new/dir': Disk full")


    let copyError = NSError(domain: "TestDomain", code: 4, userInfo: [
      NSLocalizedDescriptionKey: "Source file missing",
    ])
    let failedCopy = FileSystemError.failedToCopyFile(
      from: "/source.txt",
      to: "/dest.txt",
      underlying: copyError
    )
    #assert(failedCopy.userMessage == "Failed to copy '/source.txt' to '/dest.txt': Source file missing")
  }

  @Test func ConfigurationError() {

    let missingInfo = ConfigurationError.missingInfoFile
    #assert(missingInfo.userMessage == "Exercise info file not found. Are you in a Swiftlings directory?")


    let invalidInfo = ConfigurationError.invalidInfoFile(message: "Missing 'exercises' key")
    #assert(invalidInfo.userMessage == "Invalid exercise info file: Missing 'exercises' key")


    let incompatible = ConfigurationError.incompatibleVersion(found: "2.0", required: "1.0")
    #assert(incompatible.userMessage == "Incompatible version: found 2.0, required 1.0")
  }

  @Test func ErrorsWithSpecialCharacters() {

    let specialName = ExerciseError.notFound(name: "test-exercise_123")
    #assert(specialName.userMessage == "Exercise 'test-exercise_123' not found")


    let complexMessage = ExerciseError.compilationFailed(
      message: "error: \"string\" literal\n\tat line 10: unexpected character '🎯'"
    )
    #assert(complexMessage.userMessage.contains("\"string\" literal"))
    #assert(complexMessage.userMessage.contains("🎯"))


    let pathWithSpaces = FileSystemError.fileNotFound(
      path: "/Users/John Doe/My Documents/file.swift"
    )
    #assert(pathWithSpaces.userMessage == "File not found: /Users/John Doe/My Documents/file.swift")
  }

  @Test func ErrorAsLocalizedError() {
    let errors: [LocalizedError] = [
      ExerciseError.notFound(name: "test"),
      ProgressError.corrupted(message: "test"),
      ProcessError.timeout(executable: "test"),
      FileSystemError.fileNotFound(path: "test"),
      ConfigurationError.missingInfoFile,
    ]

    for error in errors {
      #assert(error.errorDescription != nil)
      #assert(!error.errorDescription!.isEmpty)
    }
  }
}
