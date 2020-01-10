#if os(Linux)

import XCTest
@testable import KognitaAPITests

XCTMain(
    KognitaAPITests.allTests()
)

#endif
