import Vapor
@testable import KognitaCore

class TestSessionRepositoryMock: TestSessionRepositoring {

    static func solutions(for user: User, in session: TestSessionRepresentable, pivotID: SubjectTest.Pivot.Task.ID, on conn: DatabaseConnectable) throws -> EventLoopFuture<[TaskSolution.Response]> {
        conn.future([])
    }

    static func results(in session: TestSessionRepresentable, pivotID: SubjectTest.Pivot.Task.ID, on conn: DatabaseConnectable) throws -> EventLoopFuture<TestSession.DetailedTaskResult> {
        conn.future(TestSession.DetailedTaskResult(
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

    class Logger: TestLogger {
        enum Entry {
            case finnish(session: TestSessionRepresentable, user: User)
            case answer(content: MultipleChoiseTask.Submit, session: TestSessionRepresentable, user: User)
            case results(session: TestSessionRepresentable, user: User)
        }

        var logs: [Entry] = []

        static let shared = Logger()
    }

    static func submit(content: MultipleChoiseTask.Submit, for session: TestSessionRepresentable, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<Void> {
        Logger.shared.log(entry: .answer(content: content, session: session, user: user))
        return conn.future()
    }

    static func submit(test: TestSessionRepresentable, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<Void> {
        Logger.shared.log(entry: .finnish(session: test, user: user))
        return conn.future()
    }

    static func results(in test: TestSessionRepresentable, for user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<TestSession.Results> {
        Logger.shared.log(entry: .results(session: test, user: user))
        return conn.future(
            TestSession.Results(
                testTitle: "Testing",
                testIsOpen: false,
                executedAt: .now,
                shouldPresentDetails: true,
                subjectID: 0,
                canPractice: true,
                topicResults: []
            )
        )
    }

    static func overview(in session: TestSessionRepresentable, for user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<TestSession.Overview> {
        try conn.future(
            TestSession.Overview(
                sessionID: session.requireID(),
                test: SubjectTest(
                    scheduledAt: .now,
                    duration: 0,
                    password: "",
                    title: "Test",
                    subjectID: 0,
                    isTeamBasedLearning: false
                ),
                tasks: []
            )
        )
    }

    static func getSessions(for user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<[TestSession.HighOverview]> {
        conn.future([])
    }
}
