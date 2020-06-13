import KognitaCore
import Vapor

extension TaskSolution: ModelParameterRepresentable {}
extension TaskSolution: Content {}

public protocol TaskSolutionAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: TaskSolutionRepositoring,
    UpdateData        == TaskSolution.Update.Data,
    CreateData        == TaskSolution.Create.Data,
    UpdateResponse    == TaskSolution,
    CreateResponse    == TaskSolution,
    Model             == TaskSolution {
    func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension TaskSolutionAPIControlling {

    /// Registers routes to the incoming router.
    ///
    /// - parameters:
    ///     - router: `Router` to register any new routes to.
    public func boot(router: Router) throws {

        let solutions = router.grouped("task-solutions")
        let solution = solutions.grouped(TaskSolution.parameter)

        register(create: solutions)
        register(update: solutions)
        register(delete: solutions)

        solution.post("upvote", use: self.upvote(on: ))
        solution.post("revoke-vote", use: self.revokeVote(on: ))
        solution.post("approve", use: self.approve(on: ))
    }
}
