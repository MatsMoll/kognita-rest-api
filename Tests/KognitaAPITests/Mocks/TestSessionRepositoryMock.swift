import Vapor
@testable import KognitaCore

struct TestSessionRepositoryMock: TestSessionRepositoring {

    class Logger: TestLogger {
        enum Entry {
            case finnish(session: TestSessionRepresentable, user: User)
            case answer(content: MultipleChoiceTask.Submit, session: TestSessionRepresentable, user: User)
            case results(session: TestSessionRepresentable, user: User)
        }

        var logs: [Entry] = []
    }

    let logger = Logger()
    var eventLoop: EventLoop

    func submit(content: MultipleChoiceTask.Submit, for session: TestSessionRepresentable, by user: User) throws -> EventLoopFuture<Void> {
        logger.log(entry: .answer(content: content, session: session, user: user))
        return eventLoop.future()
    }

    func submit(test: TestSessionRepresentable, by user: User) throws -> EventLoopFuture<Void> {
        logger.log(entry: .finnish(session: test, user: user))
        return eventLoop.future()
    }

    func results(in test: TestSessionRepresentable, for user: User) throws -> EventLoopFuture<TestSession.Results> {
        logger.log(entry: .results(session: test, user: user))
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

    func overview(in session: TestSessionRepresentable, for user: User) throws -> EventLoopFuture<TestSession.Overview> {
        try eventLoop.future(
            TestSession.Overview(
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

    func getSessions(for user: User) throws -> EventLoopFuture<[TestSession.HighOverview]> {
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
