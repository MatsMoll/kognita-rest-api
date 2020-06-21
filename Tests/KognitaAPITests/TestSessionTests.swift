import XCTest
@testable import KognitaCore
import KognitaAPI
import KognitaCoreTestable
import Vapor

class TestableControllers: APIControllerCollection {

    var controllers: APIControllers

    init(repositories: RepositoriesRepresentable) {
        controllers = APIControllers.defaultControllers(with: repositories)
    }

    var subjectController: SubjectAPIControlling { controllers.subjectController }
    var topicController: TopicAPIControlling { controllers.topicController }
    var subtopicController: SubtopicAPIControlling { controllers.subtopicController }
    var multipleChoiceTaskController: MultipleChoiseTaskAPIControlling { controllers.multipleChoiceTaskController }
    var typingTaskController: FlashCardTaskAPIControlling { controllers.typingTaskController }
    var practiceSessionController: PracticeSessionAPIControlling { controllers.practiceSessionController }
    var taskResultController: TaskResultAPIControlling { controllers.taskResultController }
    var subjectTestController: SubjectTestAPIControlling { controllers.subjectTestController }
    var testSessionController: TestSessionAPIControlling { controllers.testSessionController }
    var taskDiscussionController: TaskDiscussionAPIControlling { controllers.taskDiscussionController }
    var taskDiscussionResponseController: TaskDiscussionResponseAPIControlling { controllers.taskDiscussionResponseController }
    var taskSolutionController: TaskSolutionAPIControlling { controllers.taskSolutionController }
    var userController: UserAPIControlling { controllers.userController }

    static var shared: TestableControllers!

    static func testable(with repositories: RepositoriesRepresentable) -> TestableControllers {
        if shared == nil {
            shared = TestableControllers(repositories: repositories)
        }
        return shared
    }

    static func reset() {
        shared = nil
    }

    static func modifyControllers(_ modifier: @escaping (inout APIControllers) -> Void) {
        guard let shared = shared else { fatalError() }
        modifier(&shared.controllers)
    }

    func boot(router: Router) throws {
        try controllers.boot(router: router)
    }
}

class TestSessionTests: VaporTestCase {

    let rootUri = "api/test-sessions"

    lazy var subjectTestRepository: SubjectTestRepositoring = self.repositories.subjectTestRepository
    lazy var testSessionRepository: TestSessionRepositoring = self.repositories.testSessionRepository
    var mock: TestSessionRepositoryMock { testSessionRepository as! TestSessionRepositoryMock }

    override func modify(repositories: inout TestableRepositories) {
        repositories.testSessionRepository = TestSessionRepositoryMock(eventLoop: app.eventLoop)
    }

    override func setUp() {
        super.setUp()
        mock.logger.clear()
    }

    func testSavingAnswer() throws {
        do {
            let user = try User.create(on: conn)
            let session = try setupSession(for: user)
            let firstSubmission = try submissionAt(index: 1, for: session.testID)

            let submitUri = uri(for: session.id) + "/save"
            let response = try app.sendRequest(to: submitUri, method: .POST, headers: standardHeaders, body: firstSubmission, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(mock.logger.lastEntry)

            switch logEntry {
            case .answer(let data, let loggedSession, let loggedUser):
                try XCTAssertEqual(session.id, loggedSession.requireID())
                XCTAssertEqual(user.id, loggedUser.id)

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

            let submitUri = uri(for: session.id) + "/finnish"
            let response = try app.sendRequest(to: submitUri, method: .POST, headers: standardHeaders, loggedInUser: user)
            response.has(statusCode: .ok)

            let logEntry = try XCTUnwrap(mock.logger.lastEntry)

            switch logEntry {
            case .finnish(let loggedSession, let loggedUser):
                try XCTAssertEqual(session.id, loggedSession.requireID())
                XCTAssertEqual(user.id, loggedUser.id)
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

            let submitUri = uri(for: session.id) + "/results"
            let responses = try [
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user),
                app.sendFutureRequest(to: submitUri, method: .GET, headers: standardHeaders, loggedInUser: user)
            ]
                .flatten(on: conn)
                .wait()

            responses.forEach { response in
                response.has(statusCode: .ok)
                response.has(content: TestSession.Results.self)
            }

            let logEntry = try XCTUnwrap(mock.logger.lastEntry)

            switch logEntry {
            case .results(let loggedSession, let loggedUser):
                try XCTAssertEqual(session.id, loggedSession.requireID())
                XCTAssertEqual(user.id, loggedUser.id)
            default:
                XCTFail("Incorect log entry")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testVoteForSolution() {
        failableTest {
            let user = try User.create(on: conn)
            let task = try Task.create(on: conn)
            let solution = try XCTUnwrap(TaskSolution.DatabaseModel.query(on: conn).filter(\TaskSolution.taskID, .equal, task.requireID()).first().wait())

            let uri = try "/api/task-solutions/\(solution.requireID())/upvote"
            let unauthorizedResponse = try app.sendRequest(to: uri, method: .POST)
            unauthorizedResponse.has(statusCode: .unauthorized)
            let response = try app.sendRequest(to: uri, method: .POST, loggedInUser: user)
            response.has(statusCode: .ok)
        }
    }


    // MARK: - Helper functions

    func setupSession(for user: User) throws -> TestSession {
        let test = try setupTestWithTasks()
        let enterRequest = SubjectTest.Enter.Request(password: defaultTestPassword)

        return try subjectTestRepository.enter(test: test, with: enterRequest, by: user).wait()
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
            password:       defaultTestPassword,
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

    var defaultTestPassword: String { "password" }

    func uri(for sessionID: TestSession.ID) -> String {
        "\(rootUri)/\(sessionID)"
    }

    func submissionAt(index: Int, for testID: SubjectTest.ID, isCorrect: Bool = true) throws -> MultipleChoiceTask.Submit {
        let choises = try choisesAt(index: index, for: testID)
        return try MultipleChoiceTask.Submit(
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

    func multipleChoiseAnswer(with choises: [MultipleChoiseTaskChoise.ID]) -> MultipleChoiceTask.Submit {
        .init(
            timeUsed: .seconds(20),
            choises: choises,
            taskIndex: 1
        )
    }

    static let allTests = [
        ("testSavingAnswer", testSavingAnswer),
        ("testFinnishSession", testFinnishSession),
        ("testResults", testResults),
        ("testVoteForSolution", testVoteForSolution),
    ]
}
