import KognitaCore
import Vapor

public struct TaskSolutionAPIController: TaskSolutionAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.create(in: req.repositories.taskSolutionRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.update(with: req.repositories.taskSolutionRepository.updateModelWith(id: to: by: ), parameter: TaskSolution.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.taskSolutionRepository.deleteModelWith(id: by: ), parameter: TaskSolution.self)
    }

    public func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        return try req.repositories.taskSolutionRepository.upvote(
            for: req.parameters.get(TaskSolution.self),
            by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        return try req.repositories.taskSolutionRepository.revokeVote(
            for: req.parameters.get(TaskSolution.self),
            by: req.auth.require()
        )
            .transform(to: .ok)
    }

    public func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        return try req.repositories.taskSolutionRepository.approve(
            for: req.parameters.get(TaskSolution.self),
            by: req.auth.require()
        )
            .transform(to: .ok)
    }
}

extension TaskSolution {
    /// A `TaskSolutionAPIController` using the `TaskSolution.DatabaseRepository`
    public typealias DefaultAPIController = TaskSolutionAPIController
}
