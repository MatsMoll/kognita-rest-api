import KognitaCore
import Vapor

public struct TaskSolutionAPIController: TaskSolutionAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.repositories.taskSolutionRepository.create(
            from: req.content.decode(),
            by: req.auth.require()
        )
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskSolution> {
        try req.repositories.taskSolutionRepository.updateModelWith(
            id: req.parameters.get(TaskSolution.self),
            to: req.content.decode(),
            by: req.auth.require()
        )
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.taskSolutionRepository.deleteModelWith(
            id: req.parameters.get(TaskSolution.self),
            by: req.auth.require()
        )
        .transform(to: .ok)
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

    public func solutionsForTask(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.forbidden) }
        return try req.repositories.taskSolutionRepository.solutions(for: req.parameters.get(GenericTask.self), for: user)
    }
}

extension TaskSolution {
    /// A `TaskSolutionAPIController` using the `TaskSolution.DatabaseRepository`
    public typealias DefaultAPIController = TaskSolutionAPIController
}
