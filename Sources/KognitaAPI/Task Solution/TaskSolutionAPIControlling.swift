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
    static func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}


extension TaskSolutionAPIControlling {

    public func boot(router: Router) throws {

        let solutions = router.grouped("task-solutions")
        let solution = solutions.grouped(TaskSolution.parameter)

        register(create: solutions)
        register(update: solutions)
        register(delete: solutions)

        solution.post("upvote",         use: Self.upvote(on: ))
        solution.post("revoke-vote",    use: Self.revokeVote(on: ))
        solution.post("approve",        use: Self.approve(on: ))
    }
}
