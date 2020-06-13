import KognitaCore
import Vapor

public struct TaskSolutionAPIController: TaskSolutionAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some TaskSolutionRepositoring { TaskSolution.DatabaseRepository(conn: conn) }

    public func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        return try repository.upvote(
            for: req.parameters.modelID(TaskSolution.self),
            by: req.requireAuthenticated()
        )
        .transform(to: .ok)
    }

    public func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        return try repository.revokeVote(
            for: req.parameters.modelID(TaskSolution.self),
            by: req.requireAuthenticated()
        )
            .transform(to: .ok)
    }

    public func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        return try repository.approve(
            for: req.parameters.modelID(TaskSolution.self),
            by: req.requireAuthenticated()
        )
            .transform(to: .ok)
    }
}

extension TaskSolution {
    /// A `TaskSolutionAPIController` using the `TaskSolution.DatabaseRepository`
    public typealias DefaultAPIController = TaskSolutionAPIController
}
