// extensions5.swift
//
// You can provide a default implementation for your protocols using protocol extensions.
//
//  Extend the Error protocol to provide a function called `throwError` to each instance

extension Error {
	func throwError() throws {
		throw self
	}
}

func main() {
	// Provide a variable to improve exercise diagnostics.
	var implemented = true

	/// A Error type to test `throwError()` that is not subject to user visibility
	enum MyError: Error {
		case testError

		// This function is marked as dispreferred to ensure
		// that the default implementation in the Error extension
		// is used instead of this one.
		@__dispreferredOverload
		func throwError() throws {
			implemented = false
			return
		}
	}

	test("`throwError()` is validly implemented in an `Error` extension") {
		var error: MyError = .testError
		do {
			try error.throwError()
			assertFalse(true, !implemented ?
				"Make sure to implement the `throwError()` function in a `Error` extension.":
				"Make sure that you are throwing to exit the function."
			)
		} catch (let e: MyError) {
			assertTrue(e == error, "Your function should throw the error that is called on")
		} catch {
			assertFalse(true, "Out of Spec: Do not throw your own error type.")
		}
	}

	runTests()
}