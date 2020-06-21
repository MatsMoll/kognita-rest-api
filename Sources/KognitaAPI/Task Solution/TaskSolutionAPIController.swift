import KognitaCore
import Vapor

public struct TaskSolutionAPIController: TaskSolutionAPIControlling {

    let repositories: RepositoriesRepresentable

    public var repository: TaskSolutionRepositoring { repositories.taskSolutionRepository }

    public func create(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.create(in: repository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.update(with: repository.updateModelWith(id: to: by: ), parameter: TaskSolution.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: repository.deleteModelWith(id: by: ), parameter: TaskSolution.self)
    }

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
