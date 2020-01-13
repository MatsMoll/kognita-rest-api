import Vapor
@testable import KognitaCore

class SubjectTestRepositoryMock: SubjectTestRepositoring {

    class Logger: TestLogger {

        enum Entry {
            case open(test: SubjectTest, user: User)
            case enter(test: SubjectTest, user: User)
            case completionStatus(test: SubjectTest, user: User)
            case taskWith(id: SubjectTest.Pivot.Task.ID, session: TestSessionRepresentable, user: User)
            case results(test: SubjectTest, user: User)
            case create(data: SubjectTest.Create.Data, user: User?)
            case update(data: SubjectTest.Update.Data, user: User)
        }

        var logs: [Entry] = []

        static var shared = Logger()
    }

    static func open(test: SubjectTest, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest> {

        Logger.shared.log(entry: .open(test: test, user: user))
        return conn.future(test)
    }

    static func enter(test: SubjectTest, with request: SubjectTest.Enter.Request, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<TestSession> {

        Logger.shared.log(entry: .enter(test: test, user: user))
        return conn.future(TestSession(sessionID: 0, testID: 0))
    }

    static func userCompletionStatus(in test: SubjectTest, user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {

        Logger.shared.log(entry: .completionStatus(test: test, user: user))
        return conn.future(
            SubjectTest.CompletionStatus(
                amountOfCompletedUsers: 1,
                amountOfEnteredUsers: 1
            )
        )
    }

    static func taskWith(id: SubjectTest.Pivot.Task.ID, in session: TestSessionRepresentable, for user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {

        Logger.shared.log(entry: .taskWith(id: id, session: session, user: user))

        return conn.databaseConnection(to: .psql)
            .map { conn in

                try SubjectTest.MultipleChoiseTaskContent(
                    task: Task.create(on: conn),
                    multipleChoiseTask: MultipleChoiseTask.create(on: conn),
                    choises: [],
                    selectedChoises: [],
                    testTasks: []
                )
        }
    }

    static func results(for test: SubjectTest, user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest.Results> {

        Logger.shared.log(entry: .results(test: test, user: user))

        return conn.future(
            SubjectTest.Results(
                title: "Testing",
                heldAt: .now,
                taskResults: []
            )
        )
    }

    static func create(from content: SubjectTest.Create.Data, by user: User?, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest> {
        Logger.shared.log(entry: .create(data: content, user: user))
        return conn.future(SubjectTest(data: content))
    }

    static func update(model: SubjectTest, to data: SubjectTest.Update.Data, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<SubjectTest.Update.Response> {

        Logger.shared.log(entry: .update(data: data, user: user))
        return conn.future(model.update(with: data))
    }
}
