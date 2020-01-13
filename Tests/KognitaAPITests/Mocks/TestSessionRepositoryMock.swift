import Vapor
@testable import KognitaCore

class TestSessionRepositoryMock: TestSessionRepositoring {

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
                executedAt: .now,
                shouldPresentDetails: true,
                topicResults: []
            )
        )
    }
}
