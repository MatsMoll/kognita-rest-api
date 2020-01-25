import XCTest
@testable import KognitaCore
import KognitaCoreTestable
import Vapor

final class SubjectTestTests: VaporTestCase {

    private let rootUri = "api/subject-tests"

    func testCreateTest() throws {
        do {
            SubjectTestRepositoryMock.Logger.shared.clear()

            let user = try User.create(on: conn)
            let topic = try Topic.create(on: conn)
            let subtopic = try Subtopic.create(topic: topic, on: conn)
            let numberOfTasks = 4
            let taskIds = try (0..<numberOfTasks).map { _ in
                try MultipleChoiseTask.create(subtopic: subtopic, on: conn)
                    .requireID()
            }

            let createTest = SubjectTest.Create.Data(
                tasks:          taskIds,
                subjectID:      topic.subjectId,
                duration:       .minutes(10),
                scheduledAt:    Date().addingTimeInterval(.minutes(50)),
                password:       "testing",
                title:          "Testing"
            )
            let response = try app.sendRequest(to: rootUri, method: .POST, headers: standardHeaders, body: createTest, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Create.Response.self)

            let logEntry = try XCTUnwrap(SubjectTestRepositoryMock.Logger.shared.logs.last)

            switch logEntry {
            case .create(let data, let loggedUser):
                XCTAssertEqual(try user.requireID(), loggedUser?.id)

                XCTAssertEqual(data.title, createTest.title)
                XCTAssertEqual(data.duration, createTest.duration)
                XCTAssertEqual(data.password, createTest.password)
                XCTAssertEqual(data.tasks, createTest.tasks)
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateTest() throws {
        do {
            SubjectTestRepositoryMock.Logger.shared.clear()

            let user = try User.create(on: conn)
            let test = try setupTestWithTasks()
            let subtopic = try Subtopic.create(on: conn)
            let numberOfTasks = 4
            let taskIds = try (0..<numberOfTasks).map { _ in
                try MultipleChoiseTask.create(subtopic: subtopic, on: conn)
                    .requireID()
            }
            let updateTest = SubjectTest.Update.Data(
                tasks:          taskIds,
                subjectID:      test.subjectID,
                duration:       .minutes(15),
                scheduledAt:    Date().addingTimeInterval(.minutes(50)),
                password:       "testing",
                title:          "Update Test"
            )

            let response = try app.sendRequest(to: uri(for: test), method: .PUT, headers: standardHeaders, body: updateTest, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Update.Response.self)

            let logEntry = try XCTUnwrap(SubjectTestRepositoryMock.Logger.shared.logs.last)

            switch logEntry {
            case .update(let data, let loggedUser):
                XCTAssertEqual(try loggedUser.requireID(), user.id)

                XCTAssertEqual(data.title, updateTest.title)
                XCTAssertEqual(data.duration, updateTest.duration)
                XCTAssertEqual(data.password, updateTest.password)
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

//    func testDeleteTest() throws {
//        do {
//            let user = try User.create(on: conn)
//            let test = try setupTestWithTasks()
//
//            let response = try app.sendRequest(to: uri(for: test), method: .DELETE, headers: standardHeaders, loggedInUser: user)
//
//            response.has(statusCode: .ok)
//        } catch {
//            XCTFail(error.localizedDescription)
//        }
//    }

    func testOpeningTest() throws {
        do {
            SubjectTestRepositoryMock.Logger.shared.clear()

            let user = try User.create(on: conn)
            let test = try setupTestWithTasks()

            let openUri = uri(for: test) + "/open"
            let response = try app.sendRequest(to: openUri, method: .POST, headers: standardHeaders, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(SubjectTestRepositoryMock.Logger.shared.logs.last)

            switch logEntry {
            case .open(let loggedTest, let loggedUser):
                XCTAssertEqual(loggedTest.id, test.id)
                XCTAssertEqual(loggedUser.id, user.id)
                XCTAssertEqual(loggedUser.email, user.email)
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func uri(for test: SubjectTest) -> String {
        try! "\(rootUri)/\(test.requireID())"
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
            password:       "password",
            title:          "Testing"
        )

        if scheduledAt.timeIntervalSinceNow < 0 {
            let test = try SubjectTest.DatabaseRepository.create(from: data, by: user, on: conn).wait()
            return try SubjectTest.DatabaseRepository.open(test: test, by: user, on: conn).wait()
        } else {
            return try SubjectTest.DatabaseRepository.create(from: data, by: user, on: conn).wait()
        }
    }

    static let allTests = [
        ("testCreateTest", testCreateTest),
        ("testUpdateTest", testUpdateTest),
        ("testOpeningTest", testOpeningTest)
    ]
}

extension TimeInterval {

    static func minutes(_ time: Int) -> Double {
        Double(time) * 60
    }

    static func seconds(_ time: Int) -> Double {
        Double(time)
    }
}
