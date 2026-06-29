// advanced_types5.swift
//
// Followup exercise to 21.4 and 13.5
//
// While protocols can be used to require functionality,
// you may notice that you could have enough information
// to provide a default implementation.
//
//  Extend the Error protocol to provide a function called `throwError` to each instance

protocol Nameable {
	var name: String { get }
}

protocol Talking {
	func talk(_ msg: String) -> String
}

struct Person: Nameable, Talking {
	var name: String = "John"
}

extension Nameable where Self: Talking {
	func talk(_ msg: String) -> String {
		return "\(name): \(msg)"
	}
}



func main() {
	// Provide a variable to improve exercise diagnostics.
	var implemented = true
	var cheating = false

	/// A Error type to test `throwError()` that is not subject to user visibility
	struct DemoType: Nameable, Talking {
		var name: String = "Demo"

		// This function is marked as dispreferred to ensure
		// that the default implementation is used instead of this one.
		@__dispreferredOverload
		func talk(_ msg: String) throws {
			implemented = false
			return ""
		}
	}

	struct DemoType2: Nameable {
		var name: String = "Demo2"

		// This function is marked as dispreferred to ensure
		// that the default implementation is used instead of this one.
		@__dispreferredOverload
		func talk(_ msg: String) throws {
			cheating = true
			return ""
		}
	}

	test("`Person` is both `Nameable` and `Talking`") {
		assertTrue(Person.self is any Nameable, "`Person` should conform to `Nameable`")
		assertTrue(Person.self is any Talking, "`Person` should conform to `Talking`")
	}

	let message = "Hello"

	test("Talking and Nameable protocols are validly implemented") {
		var demo = DemoType()
		let response = demo.talk(message)
		assertTrue(implemented, "Can you remove a symbol from `Person`; Maybe review exercises 21.4 and 13.5")
		assertTrue(response.hasSuffix(message), "`talk(_:)` should end in the message")
		assertTrue(response.hasPrefix(demo.name), "`talk(_:)` should start `name`")
	}

	test("`talk(_:)` is only provided to types that conform to `Talking`") {
		DemoType2().talk(message)
		assertFalse(
			cheating,
			"""
			You can call `talk(_:)` without conforming to `Talking`.
			It should not be accessible without conforming to `Talking`; Maybe review exercise 21.4
			"""
		)
	}

	test("User isn't cheating with hardcoding") {
		let name = "Swiftlings"
		let demo = DemoType(name: name)
		let message = "Goodbye"
		let response = demo.talk(message)
		assertTrue(response.hasSuffix(message), "Don't reverse engineer the solution; `talk(_:)` should end in the passed message")
		assertTrue(response.hasPrefix(name), "Don't reverse engineer the solution; `talk(_:)` should start with `Nameable.name`")
	}

	runTests()
}