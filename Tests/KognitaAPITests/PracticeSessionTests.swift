//
//  PracticeSessionTests.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import XCTest
@testable import KognitaCore
import KognitaCoreTestable

final class PracticeSessionTests: VaporTestCase {

    lazy var practiceSessionRepository: some PracticeSessionRepository = PracticeSession.DatabaseRepository(conn: conn)

    func testResultsWithNoAnswers() {
        failableTest {
            let user = try User.create(on: conn)
            let task = try Task.create(on: conn)
            let session = try PracticeSession.create(in: [task.subtopicID], for: user, on: conn)
            _ = try practiceSessionRepository.end(session, for: user).wait()

            let uri = try "/api/practice-sessions/\(session.requireID())/result"
            let response = try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user)
            response.has(statusCode: .ok)
        }
    }
    
    static let allTests = [
        ("testResultsWithNoAnswers", testResultsWithNoAnswers)
    ]
}
