import Testing
import CoreFoundation // Limited
@testable import Swiftlings

@available(macOS,10_15)
@Suite struct TestDetectorTests {

  class MockFileManager: FileManager {
    var fileExistsResponses: [String: Bool] = [:]

    override func fileExists(atPath path: String) -> Bool {
      return fileExistsResponses[path] ?? false
    }
  }


  func withTemporaryFile(content: String, _ test: (URL) throws -> Void) throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".swift")

    try content.write(to: tempFile, atomically: true, encoding: .utf8)

    defer {
      try? FileManager.default.removeItem(at: tempFile)
    }

    try test(tempFile)
  }

  @Test func DetectsRunTests() throws {
    let detector = TestDetector()

    let content = """
      import CoreFoundation // Limited

      @Test func Addition() {
        assertEqual(2 + 2, 4)
      }

      runTests()
      """

    try withTemporaryFile(content: content) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == true)
    }
  }

  @Test func DetectsSwiftlingsAssert() throws {
    let detector = TestDetector()

    let content = """
      import SwiftlingsAssert

      func main() {
        print("Hello")
      }
      """

    try withTemporaryFile(content: content) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == true)
    }
  }

  @Test func DetectsAssertEqual() throws {
    let detector = TestDetector()

    let content = """
      @Test func Math() {
        assertEqual(10 / 2, 5)
        assertEqual("Hello", "Hello")
      }
      """

    try withTemporaryFile(content: content) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == true)
    }
  }

  @Test func DetectsAssertTrue() throws {
    let detector = TestDetector()

    let content = """
      @Test func Conditions() {
        assertTrue(5 > 3)
        assertTrue(isValid())
      }
      """

    try withTemporaryFile(content: content) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == true)
    }
  }

  @Test func NonTestFile() throws {
    let detector = TestDetector()

    let content = """
      import CoreFoundation // Limited

      func main() {
        print("Hello, World!")
        let result = calculate(5, 10)
        print(result)
      }

      func calculate(_ a: Int, _ b: Int) -> Int {
        return a + b
      }
      """

    try withTemporaryFile(content: content) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == false)
    }
  }

  @Test func FileReadError() {
    let detector = TestDetector()


    let nonExistentFile = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).swift")
    #assert(detector.usesTestApproach(exercisePath: nonExistentFile) == false)
  }

  @Test func VariousTestPatterns() throws {
    let detector = TestDetector()

    let testCases = [

      ("func main() { runTests() }", true),
      ("runTests()", true),
      ("  runTests()  ", true),


      ("assertEqual(a, b)", true),
      ("  assertEqual(expected, actual)  ", true),


      ("assertTrue(condition)", true),
      ("assertTrue(x > 0)", true),


      ("import SwiftlingsAssert", true),
      ("@testable import SwiftlingsAssert", true),


      ("func run() { print(\"test\") }", false),
      ("// runTests()", true),
      ("let runTestsVar = true", false),
      ("print(\"assertEqual\")", true),
    ]

    for (content, expectedResult) in testCases {
      try withTemporaryFile(content: content) { file in
        #assert(detector.usesTestApproach(exercisePath: file) == expectedResult,
          "Failed for content: \(content)"
        )
      }
    }
  }

  @Test func CaseSensitivity() throws {
    let detector = TestDetector()


    let wrongCaseContent = """
      RUNTESTS()
      AssertEqual(1, 1)
      ASSERTTRUE(true)
      import swiftlingsassert
      """

    try withTemporaryFile(content: wrongCaseContent) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == false)
    }
  }

  @Test func MixedContent() throws {
    let detector = TestDetector()

    let mixedContent = """
      import CoreFoundation // Limited


      func calculateSum(_ a: Int, _ b: Int) -> Int {
        return a + b
      }

      @Test func CalculateSum() {
        assertEqual(calculateSum(2, 3), 5)
        assertEqual(calculateSum(-1, 1), 0)
        assertEqual(calculateSum(0, 0), 0)
      }

      @Test func Multiplication() {
        let result = 4 * 5
        assertTrue(result == 20)
      }


      runTests()
      """

    try withTemporaryFile(content: mixedContent) { file in
      #assert(detector.usesTestApproach(exercisePath: file) == true)
    }
  }
}
