import KognitaCore
import Vapor

extension TaskSolution: ModelParameterRepresentable {}

public protocol TaskSolutionAPIControlling:
    CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: TaskSolutionRepositoring,
    UpdateData        == TaskSolution.Update.Data,
    CreateData        == TaskSolution.Create.Data,
    UpdateResponse    == TaskSolution.Update.Response,
    CreateResponse    == TaskSolution.Create.Response,
    Model             == TaskSolution
{
    static func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    static func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
}


extension TaskSolutionAPIControlling {

    public func boot(router: Router) throws {

        let solution = router.grouped("task-solutions", TaskSolution.parameter)

        register(create: router.grouped("task-solutions"))
        register(update: solution)
        register(delete: solution)

        solution.post("upvote", use: Self.upvote(on: ))
        solution.post("revoke-vote", use: Self.revokeVote(on: ))
    }
}
