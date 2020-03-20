import KognitaCore
import Vapor

public protocol TestSessionAPIControlling: RouteCollection {

    static func submit(test req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func submit(multipleChoiseTask req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func results(on req: Request) throws -> EventLoopFuture<TestSession.Results>
    static func detailedTaskResult(on req: Request) throws -> EventLoopFuture<TestSession.DetailedTaskResult>
    static func overview(on req: Request) throws -> EventLoopFuture<TestSession.Overview>
    static func solutions(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]>
}

extension TestSessionAPIControlling {

    public func boot(router: Router) throws {
        
        let session = router.grouped("test-sessions", TaskSession.TestParameter.parameter)

        session.post("finnish",                             use: Self.submit(test: ))
        session.post("save",                                use: Self.submit(multipleChoiseTask: ))
        session.get("results",                              use: Self.results(on: ))
        session.get("tasks", Int.parameter, "results",      use: Self.detailedTaskResult(on: ))
        session.get("overview",                             use: Self.overview(on: ))
        session.get("tasks", Int.parameter, "solutions",    use: Self.solutions(on: ))
    }
}
