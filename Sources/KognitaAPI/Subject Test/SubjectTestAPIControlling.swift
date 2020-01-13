import Vapor
import FluentPostgreSQL
import KognitaCore

protocol SubjectTestAPIControlling:
    CreateModelAPIController,
    UpdateModelAPIController,
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
}

extension SubjectTestAPIControlling {

    public func boot(router: Router) {

        let test            = router.grouped("subject-tests")
        let testInstance    = router.grouped("subject-tests", SubjectTest.parameter)

        register(create: test)
        register(update: test)

        testInstance.post("open",                               use: Self.open(on: ))
        testInstance.post("enter",                              use: Self.enter(on: ))

        testInstance.get("status",                              use: Self.userCompletionStatus(on: ))
        testInstance.get("results",                             use: Self.results(on: ))
        testInstance.get(SubjectTest.Pivot.Task.ID.parameter,   use: Self.taskForID(on: ))
    }
}
