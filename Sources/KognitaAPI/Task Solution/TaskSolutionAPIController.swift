import KognitaCore
import Vapor

public final class TaskSolutionAPIController<Repository: TaskSolutionRepositoring>: TaskSolutionAPIControlling {

    public static func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSolution.self, on: req)
            .flatMap { solution in
                try Repository.upvote(for: solution.requireID(), by: user, on: req)
                    .transform(to: .ok)
        }
    }

    public static func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSolution.self, on: req)
            .flatMap { solution in
                try Repository.revokeVote(for: solution.requireID(), by: user, on: req)
                    .transform(to: .ok)
        }
    }

    public static func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSolution.self, on: req)
            .flatMap { solution in

                try Repository.approve(for: solution.requireID(), by: user, on: req)
                    .transform(to: .ok)
        }
    }
}

extension TaskSolution {

    public typealias DefaultAPIController = TaskSolutionAPIController<TaskSolution.DatabaseRepository>
}
