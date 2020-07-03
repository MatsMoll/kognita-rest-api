import XCTest
@testable import KognitaCore
import KognitaCoreTestable
import Vapor

extension SubjectTest.Create.Data: Content {}

final class SubjectTestTests: VaporTestCase {

    var subjectTestRepository: SubjectTestRepositoring { repositories.subjectTestRepository }
    var mock: SubjectTestRepositoryMock { subjectTestRepository as! SubjectTestRepositoryMock }

    override func modify(repositories: TestableRepositories) {
        repositories.subjectTestRepository = SubjectTestRepositoryMock(eventLoop: app.eventLoopGroup.next())
    }

    private let rootUri = "api/subject-tests"

    func testCreateTest() throws {
        mock.logger.clear()

        let user = try User.create(on: app)
        let topic = try Topic.create(on: app)
        let subtopic = try Subtopic.create(topic: topic, on: app)
        let numberOfTasks = 4
        let taskIds = try (0..<numberOfTasks).map { _ in
            try MultipleChoiceTask.create(subtopic: subtopic, on: app).id
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
        try app.sendRequest(to: rootUri, method: .POST, headers: standardHeaders, body: createTest, loggedInUser: user) { response in
            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Create.Response.self)

            let logEntry = try XCTUnwrap(self.mock.logger.logs.last)

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
        }
    }

    func testUpdateTest() throws {
        mock.logger.clear()

        let user = try User.create(on: app)
        let test = try setupTestWithTasks()
        let subtopic = try Subtopic.create(on: app)
        let numberOfTasks = 4
        let taskIds = try (0..<numberOfTasks).map { _ in
            try MultipleChoiceTask.create(subtopic: subtopic, on: app).id
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

        try app.sendRequest(to: uri(for: test), method: .PUT, headers: standardHeaders, body: updateTest, loggedInUser: user) { response in
            response.has(statusCode: .ok)
            response.has(content: SubjectTest.Update.Response.self)

            let logEntry = try XCTUnwrap(self.mock.logger.logs.last)

            switch logEntry {
            case .update(let data, let loggedUser):
                XCTAssertEqual(loggedUser.id, user.id)

                XCTAssertEqual(data.title, updateTest.title)
                XCTAssertEqual(data.duration, updateTest.duration)
                XCTAssertEqual(data.password, updateTest.password)
            default:
                XCTFail("Incorect log entry")
            }
        }
    }

//    func testDeleteTest() throws {
//        do {
//            let user = try User.create(on: app)
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
        mock.logger.clear()

        let user = try User.create(on: app)
        let test = try setupTestWithTasks()

        let openUri = uri(for: test) + "/open"
        try app.sendRequest(to: openUri, method: .POST, headers: standardHeaders, loggedInUser: user) { response in
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(self.mock.logger.logs.last)

            switch logEntry {
            case .open(let loggedTest, let loggedUser):
                XCTAssertEqual(loggedTest.id, test.id)
                XCTAssertEqual(loggedUser.id, user.id)
                XCTAssertEqual(loggedUser.email, user.email)
            default:
                XCTFail("Incorect log entry")
            }
        }
    }

    func uri(for test: SubjectTest) -> String {
        "\(rootUri)/\(test.id)"
    }

    func setupTestWithTasks(scheduledAt: Date = .now, duration: TimeInterval = .minutes(10), numberOfTasks: Int = 3) throws -> SubjectTest {
        let topic = try Topic.create(on: app)
        let subtopic = try Subtopic.create(topic: topic, on: app)
        let taskIds = try (0..<numberOfTasks).map { _ in
            try MultipleChoiceTask.create(subtopic: subtopic, on: app).id
        }
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: app)
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: app)
        _ = try MultipleChoiceTask.create(subtopic: subtopic, on: app)

        let user = try User.create(on: app)

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
