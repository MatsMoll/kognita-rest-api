import Vapor
@testable import KognitaCore

struct TestSessionRepositoryMock: TestSessionRepositoring {

    func testIDFor(id: TestSession.ID) -> EventLoopFuture<SubjectTest.ID> {
        eventLoop.future(1)
    }

    func sessionReporesentableWith(id: TestSession.ID) -> EventLoopFuture<TestSessionRepresentable> {
        eventLoop.future(
            TestSession.TestParameter(
                session: .init(userID: 1),
                testSession: .init(
                    sessionID: 1,
                    testID: 1
                )
            )
        )
    }


    class Logger: TestLogger {
        enum Entry {
            case finnish(sessionID: TestSession.ID, user: User)
            case answer(content: MultipleChoiceTask.Submit, sessionID: TestSession.ID, user: User)
            case results(sessionID: TestSession.ID, user: User)
        }

        var logs: [Entry] = []
    }

    let logger = Logger()
    var eventLoop: EventLoop

    func submit(content: MultipleChoiceTask.Submit, sessionID: TestSession.ID, by user: User) -> EventLoopFuture<Void> {
        logger.log(entry: .answer(content: content, sessionID: sessionID, user: user))
        return eventLoop.future()
    }

    func submit(testID: TestSession.ID, by user: User) throws -> EventLoopFuture<Void> {
        logger.log(entry: .finnish(sessionID: testID, user: user))
        return eventLoop.future()
    }

    func results(in testID: TestSession.ID, for user: User) -> EventLoopFuture<TestSession.Results> {
        logger.log(entry: .results(sessionID: testID, user: user))
        return eventLoop.future(
            TestSession.Results(
                testTitle: "Testing",
                endedAt: .now,
                testIsOpen: false,
                executedAt: .now,
                shouldPresentDetails: true,
                subjectID: 0,
                canPractice: true,
                topicResults: []
            )
        )
    }

    func overview(in session: TestSessionRepresentable, for user: User) throws -> EventLoopFuture<TestSession.PreSubmitOverview> {
        try eventLoop.future(
            TestSession.PreSubmitOverview(
                sessionID: session.requireID(),
                test: SubjectTest(
                    id: 0,
                    createdAt: .now,
                    subjectID: 0,
                    duration: .minutes(1),
                    scheduledAt: .now,
                    password: "",
                    title: "",
                    isTeamBasedLearning: false,
                    taskIDs: []
                ),
                tasks: []
            )
        )
    }

    func getSessions(for user: User) -> EventLoopFuture<[TestSession.CompletedOverview]> {
        eventLoop.future([])
    }

    func solutions(for user: User, in session: TestSessionRepresentable, pivotID: Int) throws -> EventLoopFuture<[TaskSolution.Response]> {
        eventLoop.future([])
    }

    func results(in session: TestSessionRepresentable, pivotID: Int) throws -> EventLoopFuture<TestSession.DetailedTaskResult> {
        eventLoop.future(TestSession.DetailedTaskResult(
            taskID: 1,
            description: nil,
            question: "Test",
            isMultipleSelect: false,
            testSessionID: session.testID,
            choises: [],
            selectedChoises: []
            )
        )
    }

    func createResult(for session: TestSessionRepresentable) throws -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
