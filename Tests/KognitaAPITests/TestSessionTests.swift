import XCTest
@testable import KognitaCore
import KognitaCoreTestable
import Vapor

class TestSessionTests: VaporTestCase {

    let rootUri = "api/test-sessions"

    override func setUp() {
        super.setUp()
        TestSessionRepositoryMock.Logger.shared.clear()
    }

    func testSavingAnswer() throws {
        do {
            let user = try User.create(on: conn)
            let session = try setupSession(for: user)
            let firstSubmission = try submissionAt(index: 1, for: session.testID)

            let submitUri = try uri(for: session.requireID()) + "/save"
            let response = try app.sendRequest(to: submitUri, method: .POST, headers: standardHeaders, body: firstSubmission, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(TestSessionRepositoryMock.Logger.shared.lastEntry)

            switch logEntry {
            case .answer(let data, let loggedSession, let loggedUser):
                try XCTAssertEqual(session.requireID(), loggedSession.requireID())
                try XCTAssertEqual(user.requireID(), loggedUser.requireID())

                XCTAssertEqual(firstSubmission.choises, data.choises)
                XCTAssertEqual(firstSubmission.taskIndex, data.taskIndex)
                XCTAssertEqual(firstSubmission.timeUsed, data.timeUsed)
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFinnishSession() throws {
        do {
            let user = try User.create(on: conn)
            let session = try setupSession(for: user)

            let submitUri = try uri(for: session.requireID()) + "/finnish"
            let response = try app.sendRequest(to: submitUri, method: .POST, headers: standardHeaders, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(TestSessionRepositoryMock.Logger.shared.lastEntry)

            switch logEntry {
            case .finnish(let loggedSession, let loggedUser):
                try XCTAssertEqual(session.requireID(), loggedSession.requireID())
                try XCTAssertEqual(user.requireID(), loggedUser.requireID())
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testResults() throws {
        do {
            let user = try User.create(on: conn)
            let session = try setupSession(for: user)

            let submitUri = try uri(for: session.requireID()) + "/results"
            let response = try app.sendRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: TestSession.Results.self)

            let logEntry = try XCTUnwrap(TestSessionRepositoryMock.Logger.shared.lastEntry)

            switch logEntry {
            case .results(let loggedSession, let loggedUser):
                try XCTAssertEqual(session.requireID(), loggedSession.requireID())
                try XCTAssertEqual(user.requireID(), loggedUser.requireID())
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }


    // MARK: - Helper functions

    func setupSession(for user: User) throws -> TestSession {
        let test = try setupTestWithTasks()
        let enterRequest = SubjectTest.Enter.Request(password: defaultTestPassword)

        return try SubjectTest.DatabaseRepository.enter(test: test, with: enterRequest, by: user, on: conn).wait()
    }

    func setupTestWithTasks(scheduledAt: Date = .now, duration: TimeInterval = .minutes(10), numberOfTasks: Int = 3) throws -> SubjectTest {
        let topic = try Topic.create(on: conn)
        let subtopic = try Subtopic.create(topic: topic, on: conn)
        let taskIds = try (0..<numberOfTasks).map { _ in
            try MultipleChoiseTask.create(subtopic: subtopic, on: conn)
                .requireID()
        }
        _ = try MultipleChoiseTask.create(subtopic: subtopic, on: conn)
        _ = try MultipleChoiseTask.create(subtopic: subtopic, on: conn)
        _ = try MultipleChoiseTask.create(subtopic: subtopic, on: conn)

        let user = try User.create(on: conn)

        let data = SubjectTest.Create.Data(
            tasks:          taskIds,
            subjectID:      topic.subjectId,
            duration:       duration,
            scheduledAt:    scheduledAt,
            password:       defaultTestPassword,
            title:          "Testing"
        )

        if scheduledAt.timeIntervalSinceNow < 0 {
            let test = try SubjectTest.DatabaseRepository.create(from: data, by: user, on: conn).wait()
            return try SubjectTest.DatabaseRepository.open(test: test, by: user, on: conn).wait()
        } else {
            return try SubjectTest.DatabaseRepository.create(from: data, by: user, on: conn).wait()
        }
    }

    var defaultTestPassword: String { "password" }

    func uri(for sessionID: TestSession.ID) -> String {
        "\(rootUri)/\(sessionID)"
    }

    func submissionAt(index: Int, for testID: SubjectTest.ID, isCorrect: Bool = true) throws -> MultipleChoiseTask.Submit {
        let choises = try choisesAt(index: index, for: testID)
        return try MultipleChoiseTask.Submit(
            timeUsed: .seconds(20),
            choises: choises.filter { $0.isCorrect == isCorrect }.map { try $0.requireID() },
            taskIndex: index
        )
    }

    func choisesAt(index: Int, for testID: SubjectTest.ID) throws -> [MultipleChoiseTaskChoise] {
        try SubjectTest.Pivot.Task
            .query(on: conn)
            .sort(\.createdAt)
            .filter(\.testID, .equal, testID)
            .filter(\.id, .equal, index)
            .join(\MultipleChoiseTaskChoise.taskId, to: \SubjectTest.Pivot.Task.taskID)
            .decode(MultipleChoiseTaskChoise.self)
            .all()
            .wait()
    }

    func multipleChoiseAnswer(with choises: [MultipleChoiseTaskChoise.ID]) -> MultipleChoiseTask.Submit {
        .init(
            timeUsed: .seconds(20),
            choises: choises,
            taskIndex: 1
        )
    }

    static let allTests = [
        ("testSavingAnswer", testSavingAnswer),
        ("testFinnishSession", testFinnishSession),
        ("testResults", testResults)
    ]
}
