import Vapor
import FluentPostgreSQL
import KognitaCore

public protocol SubjectTestAPIControlling:
    CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    CreateData      == SubjectTest.Create.Data,
    CreateResponse  == SubjectTest.Create.Response,
    UpdateData      == SubjectTest.Update.Data,
    UpdateResponse  == SubjectTest.Update.Response,
    Model           == SubjectTest
{
    static func open(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func enter(on req: Request) throws -> EventLoopFuture<TestSession>
    static func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus>
    static func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent>
    static func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results>
    static func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse>
    static func test(withID req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse>
}

extension SubjectTestAPIControlling {

    public func boot(router: Router) {

        let test            = router.grouped("subject-tests")
        let testInstance    = router.grouped("subject-tests", SubjectTest.parameter)

        register(create: test)
        register(update: test)
        register(delete: test)

        router.get("subjects", Subject.parameter, "subject-tests",  use: Self.allInSubject(on: ))

        testInstance.post("open",                                   use: Self.open(on: ))
        testInstance.post("enter",                                  use: Self.enter(on: ))

        testInstance.get("status",                                  use: Self.userCompletionStatus(on: ))
        testInstance.get("results",                                 use: Self.results(on: ))
        testInstance.get(SubjectTest.Pivot.Task.ID.parameter,       use: Self.taskForID(on: ))
        testInstance.get("/",                                       use: Self.test(withID: ))
    }
}
