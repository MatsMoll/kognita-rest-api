import KognitaCore
import Vapor

public protocol TestSessionAPIControlling: RouteCollection {

    func submit(test req: Request) throws -> EventLoopFuture<HTTPStatus>
    func submit(multipleChoiseTask req: Request) throws -> EventLoopFuture<HTTPStatus>
    func results(on req: Request) throws -> EventLoopFuture<TestSession.Results>
    func detailedTaskResult(on req: Request) throws -> EventLoopFuture<TestSession.DetailedTaskResult>
    func overview(on req: Request) throws -> EventLoopFuture<TestSession.Overview>
    func solutions(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]>
}

extension TestSession: ModelParameterRepresentable {}
extension TestSession.Results: Content {}
extension TestSession.Overview: Content {}

extension TestSessionAPIControlling {

    /// Registers routes to the incoming router.
    ///
    /// - parameters:
    ///     - router: `Router` to register any new routes to.
    public func boot(router: Router) throws {

        let session = router.grouped("test-sessions", TestSession.parameter)

        session.post("finnish", use: self.submit(test: ))
        session.post("save", use: self.submit(multipleChoiseTask: ))
        session.get("results", use: self.results(on: ))
        session.get("tasks", Int.parameter, "results", use: self.detailedTaskResult(on: ))
        session.get("overview", use: self.overview(on: ))
        session.get("tasks", Int.parameter, "solutions", use: self.solutions(on: ))
    }
}
