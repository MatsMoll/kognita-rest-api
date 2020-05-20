import Vapor
import FluentPostgreSQL
import KognitaCore

/// A definition of a API that can controll a SubjectTest
public protocol SubjectTestAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: SubjectTestRepositoring,
    CreateData      == SubjectTest.Create.Data,
    CreateResponse  == SubjectTest.Create.Response,
    UpdateData      == SubjectTest.Update.Data,
    UpdateResponse  == SubjectTest.Update.Response,
    Model           == SubjectTest {

    /// Opens the test for students to join
    /// - Parameter req: The HTTP request
    /// - Returns: 200 ok if successfull
    static func open(on req: Request) throws -> EventLoopFuture<HTTPStatus>

    /// A call that makes it possible to enter a test for a student
    /// - Parameter req: The HTTP request
    /// - Returns: A Future `TestSession` associated with the logged inn user
    static func enter(on req: Request) throws -> EventLoopFuture<TestSession>

    static func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus>
    static func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent>

    /// The overall results for the test
    /// - Parameter req: The HTTP request
    /// - Throws: If the logged inn user is not a moderator in the subject
    /// - Returns: A Future `TestSession` associated with the logged inn user
    static func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results>
    static func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse>
    static func test(withID req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse>

    /// Ends the `SubjectTest`
    /// - Throws: If the user is not a moderator in the associated `Subject`
    /// - Parameter req: The HTTP request
    /// - Returns: 200 ok if successfull
    static func end(req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func scoreHistogram(req: Request) throws -> EventLoopFuture<SubjectTest.ScoreHistogram>
}

extension SubjectTestAPIControlling {

    public func boot(router: Router) {

        let test            = router.grouped("subject-tests")
        let testInstance    = router.grouped("subject-tests", SubjectTest.parameter)

        register(create: test)
        register(update: test)
        register(delete: test)

        router.get("subjects", Subject.parameter, "subject-tests", use: Self.allInSubject(on: ))

        testInstance.post("end", use: Self.end(req: ))
        testInstance.post("open", use: Self.open(on: ))
        testInstance.post("enter", use: Self.enter(on: ))

        testInstance.get("status", use: Self.userCompletionStatus(on: ))
        testInstance.get("results", use: Self.results(on: ))
        testInstance.get("results/score-histogram", use: Self.scoreHistogram(req: ))
        testInstance.get(SubjectTest.Pivot.Task.ID.parameter, use: Self.taskForID(on: ))
        testInstance.get("/", use: Self.test(withID: ))
    }
}
