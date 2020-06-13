import XCTest
@testable import KognitaCore
import KognitaCoreTestable
import Vapor

extension SubjectTest.Create.Data: Content {}

final class SubjectTestTests: VaporTestCase {

    lazy var subjectTestRepository: some SubjectTestRepositoring = SubjectTestRepositoryMock(eventLoop: conn.eventLoop)
    var mock: SubjectTestRepositoryMock { subjectTestRepository as! SubjectTestRepositoryMock }

    private let rootUri = "api/subject-tests"

    func testCreateTest() throws {
        do {
            mock.logger.clear()

            let user = try User.create(on: conn)
            let topic = try Topic.create(on: conn)
            let subtopic = try Subtopic.create(topic: topic, on: conn)
            let numberOfTasks = 4
            let taskIds = try (0..<numberOfTasks).map { _ in
                try MultipleChoiceTask.create(subtopic: subtopic, on: conn).id
            }

            let createTest = SubjectTest.Create.Data(
                tasks:          taskIds,
                subjectID:      topic.subjectID,
                duration:       .minutes(10),
                scheduledAt:    Date().addingTimeInterval(.minutes(50)),
                password:       "testing",
                title:          "Testing",
                isTeamBasedLearning: false
            )
            let response = try app.sendRequest(to: rootUri, method: .POST, headers: standardHeaders, body: createTest, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Create.Response.self)

            let logEntry = try XCTUnwrap(mock.logger.logs.last)

            switch logEntry {
            case .create(let data, let loggedUser):
                XCTAssertEqual(user.id, loggedUser?.id)

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
            mock.logger.clear()

            let user = try User.create(on: conn)
            let test = try setupTestWithTasks()
            let subtopic = try Subtopic.create(on: conn)
            let numberOfTasks = 4
            let taskIds = try (0..<numberOfTasks).map { _ in
                try MultipleChoiceTask.create(subtopic: subtopic, on: conn).id
            }
            let updateTest = SubjectTest.Update.Data(
                tasks:          taskIds,
                subjectID:      test.subjectID,
                duration:       .minutes(15),
                scheduledAt:    Date().addingTimeInterval(.minutes(50)),
                password:       "testing",
                title:          "Update Test",
                isTeamBasedLearning: false
            )

            let response = try app.sendRequest(to: uri(for: test), method: .PUT, headers: standardHeaders, body: updateTest, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Update.Response.self)

            let logEntry = try XCTUnwrap(mock.logger.logs.last)

            switch logEntry {
            case .update(let data, let loggedUser):
                XCTAssertEqual(loggedUser.id, user.id)

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
            mock.logger.clear()

            let user = try User.create(on: conn)
            let test = try setupTestWithTasks()

            let openUri = uri(for: test) + "/open"
            let response = try app.sendRequest(to: openUri, method: .POST, headers: standardHeaders, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(mock.logger.logs.last)

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
        "\(rootUri)/\(test.id)"
    }

    func setupTestWithTasks(scheduledAt: Date = .now, duration: TimeInterval = .minutes(10), numberOfTasks: Int = 3) throws -> SubjectTest {
        let topic = try Topic.create(on: conn)
        let subtopic = try Subtopic.create(topic: topic, on: conn)
        let taskIds = try (0..<numberOfTasks).map { _ in
            try MultipleChoiceTask.create(subtopic: subtopic, on: conn).id
        }
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)

        let user = try User.create(on: conn)

        let data = SubjectTest.Create.Data(
            tasks:          taskIds,
            subjectID:      topic.subjectID,
            duration:       duration,
            scheduledAt:    scheduledAt,
            password:       "password",
            title:          "Testing",
            isTeamBasedLearning: false
        )

        if scheduledAt.timeIntervalSinceNow < 0 {
            let test = try subjectTestRepository.create(from: data, by: user).wait()
            return try subjectTestRepository.open(test: test, by: user).wait()
        } else {
            return try subjectTestRepository.create(from: data, by: user).wait()
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
