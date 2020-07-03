import Vapor
@testable import KognitaCore

extension SubjectTest {
    fileprivate static let dummy = SubjectTest(id: 0, createdAt: .now, subjectID: 0, duration: .minutes(1), openedAt: .now, endedAt: nil, scheduledAt: .now, password: "", title: "", isTeamBasedLearning: false, taskIDs: [])
    fileprivate static func dummy(withID id: Int) -> SubjectTest { SubjectTest(id: id, createdAt: .now, subjectID: 0, duration: .minutes(1), openedAt: .now, endedAt: nil, scheduledAt: .now, password: "", title: "", isTeamBasedLearning: false, taskIDs: []) }
}

struct SubjectTestRepositoryMock: SubjectTestRepositoring {

    class Logger: TestLogger {

        enum Entry {
            case open(test: SubjectTest, user: User)
            case enter(test: SubjectTest, user: User)
            case completionStatus(test: SubjectTest, user: User)
            case taskWith(id: Int, session: TestSessionRepresentable, user: User)
            case results(test: SubjectTest, user: User)
            case create(data: SubjectTest.Create.Data, user: User?)
            case update(data: SubjectTest.Update.Data, user: User)
        }

        var logs: [Entry] = []
    }

    var logger = Logger()
    let eventLoop: EventLoop

    func currentlyOpenTest(for user: User) throws -> EventLoopFuture<SubjectTest.UserOverview?> {
        eventLoop.future(nil)
    }

    func currentlyOpenTest(in subject: Subject, user: User) throws -> EventLoopFuture<SubjectTest.UserOverview?> {
        eventLoop.future(nil)
    }
    
    func open(test: SubjectTest, by user: User) throws -> EventLoopFuture<SubjectTest> {
        logger.log(entry: .open(test: test, user: user))
        return eventLoop.future(test)
    }

    func enter(test: SubjectTest, with request: SubjectTest.Enter.Request, by user: User) -> EventLoopFuture<TestSession> {
        logger.log(entry: .enter(test: test, user: user))
        return eventLoop.future(TestSession(id: 0, createdAt: .now, testID: 0))
    }

    func userCompletionStatus(in test: SubjectTest, user: User) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {
        logger.log(entry: .completionStatus(test: test, user: user))
        return eventLoop.future(
            SubjectTest.CompletionStatus(
                amountOfCompletedUsers: 1,
                amountOfEnteredUsers: 1
            )
        )
    }

    func taskWith(id: Int, in session: TestSessionRepresentable, for user: User) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {

        logger.log(entry: .taskWith(id: id, session: session, user: user))

        return eventLoop.future(
            SubjectTest.MultipleChoiseTaskContent(
                test: .dummy,
                task: MultipleChoiceTask(id: 0, subtopicID: 0, question: "", isTestable: false, isMultipleSelect: false, choises: []),
                choises: [],
                testTasks: []
            )
        )
    }

    func results(for test: SubjectTest, user: User) throws -> EventLoopFuture<SubjectTest.Results> {
        logger.log(entry: .results(test: test, user: user))

        return eventLoop.future(
            SubjectTest.Results(
                title: "Testing",
                heldAt: .now,
                taskResults: [],
                averageScore: 0,
                subjectID: test.subjectID,
                subjectName: "Subject",
                userResults: []
            )
        )
    }

    func all(in subject: Subject, for user: User) throws -> EventLoopFuture<[SubjectTest]> {
        eventLoop.future([])
    }

    func taskIDsFor(testID id: SubjectTest.ID) throws -> EventLoopFuture<[Task.ID]> {
        eventLoop.future([])
    }

    func firstTaskID(testID: SubjectTest.ID) throws -> EventLoopFuture<Int?> {
        eventLoop.future(nil)
    }

    func end(test: SubjectTest, by user: User) throws -> EventLoopFuture<Void> {
        eventLoop.future(())
    }

    func scoreHistogram(for test: SubjectTest, user: User) throws -> EventLoopFuture<SubjectTest.ScoreHistogram> {
        eventLoop.future(SubjectTest.ScoreHistogram(scores: []))
    }

    func isOpen(testID: SubjectTest.ID) -> EventLoopFuture<Bool> {
        eventLoop.future(false)
    }

    func detailedUserResults(for test: SubjectTest, maxScore: Double, user: User) throws -> EventLoopFuture<[SubjectTest.UserResult]> {
        eventLoop.future([])
    }

    func stats(for subject: Subject) throws -> EventLoopFuture<[SubjectTest.DetailedResult]> {
        eventLoop.future([])
    }

    func create(from content: SubjectTest.Create.Data, by user: User?) throws -> EventLoopFuture<SubjectTest> {
        logger.log(entry: .create(data: content, user: user))
        let response = SubjectTest.DatabaseModel(data: content)
        response.id = 1
        return try eventLoop.future(response.content())
    }

    func updateModelWith(id: Int, to data: SubjectTest.Update.Data, by user: User) throws -> EventLoopFuture<SubjectTest> {
        logger.log(entry: .update(data: data, user: user))
        return eventLoop.future(.dummy)
    }

    func deleteModelWith(id: Int, by user: User?) throws -> EventLoopFuture<Void> {
        eventLoop.future(())
    }

    func find(_ id: Int, or error: Error) -> EventLoopFuture<SubjectTest> {
        eventLoop.future(.dummy(withID: id))
    }

    func find(_ id: Int) -> EventLoopFuture<SubjectTest?> {
        eventLoop.future(nil)
    }
}
