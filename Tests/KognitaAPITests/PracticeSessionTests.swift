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

    lazy var practiceSessionRepository: PracticeSessionRepository = self.repositories.practiceSessionRepository

    func testResultsWithNoAnswers() {
        failableTest {
            let user = try User.create(on: app)
            let task = try TaskDatabaseModel.create(on: app)
            let session = try PracticeSession.create(in: [task.$subtopic.id], for: user, on: app)
            _ = try practiceSessionRepository.end(session, for: user).wait()

            let uri = try "/api/practice-sessions/\(session.requireID())/result"
            try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user) { response in
                response.has(statusCode: .ok)
            }
        }
    }
    
    static let allTests = [
        ("testResultsWithNoAnswers", testResultsWithNoAnswers)
    ]
}
