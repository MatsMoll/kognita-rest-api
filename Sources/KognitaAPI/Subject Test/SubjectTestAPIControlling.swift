import Vapor
import FluentPostgreSQL
import KognitaCore

extension SubjectTest: ModelParameterRepresentable {}
extension SubjectTest.Results: Content {}
extension SubjectTest.ScoreHistogram: Content {}
extension SubjectTest.MultipleChoiseTaskContent: Content {}

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
    func open(on req: Request) throws -> EventLoopFuture<HTTPStatus>

    /// A call that makes it possible to enter a test for a student
    /// - Parameter req: The HTTP request
    /// - Returns: A Future `TestSession` associated with the logged inn user
    func enter(on req: Request) throws -> EventLoopFuture<TestSession>

    func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus>
    func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent>

    /// The overall results for the test
    /// - Parameter req: The HTTP request
    /// - Throws: If the logged inn user is not a moderator in the subject
    /// - Returns: A Future `TestSession` associated with the logged inn user
    func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results>
    func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse>
    func test(withID req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse>

    /// Ends the `SubjectTest`
    /// - Throws: If the user is not a moderator in the associated `Subject`
    /// - Parameter req: The HTTP request
    /// - Returns: 200 ok if successfull
    func end(req: Request) throws -> EventLoopFuture<HTTPStatus>
    func scoreHistogram(req: Request) throws -> EventLoopFuture<SubjectTest.ScoreHistogram>
}

extension SubjectTestAPIControlling {

    public func boot(router: Router) {

        let test            = router.grouped("subject-tests")
        let testInstance    = router.grouped("subject-tests", SubjectTest.parameter)

        register(create: test)
        register(update: test)
        register(delete: test)

        router.get("subjects", Subject.parameter, "subject-tests", use: self.allInSubject(on: ))

        testInstance.post("end", use: self.end(req: ))
        testInstance.post("open", use: self.open(on: ))
        testInstance.post("enter", use: self.enter(on: ))

        testInstance.get("status", use: self.userCompletionStatus(on: ))
        testInstance.get("results", use: self.results(on: ))
        testInstance.get("results/score-histogram", use: self.scoreHistogram(req: ))
        testInstance.get(Int.parameter, use: self.taskForID(on: ))
        testInstance.get("/", use: self.test(withID: ))
    }
}
