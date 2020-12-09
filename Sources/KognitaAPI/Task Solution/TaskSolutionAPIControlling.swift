import KognitaCore
import Vapor

extension TaskSolution: ModelParameterRepresentable {}
extension TaskSolution: Content {}

public protocol TaskSolutionAPIControlling: CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<TaskSolution>
    func update(on req: Request) throws -> EventLoopFuture<TaskSolution>
    func upvote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    func revokeVote(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    func approve(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func solutionsForTask(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]>
}

extension TaskSolutionAPIControlling {

    /// Registers routes to the incoming router.
    ///
    /// - parameters:
    ///     - router: `Router` to register any new routes to.
    public func boot(routes: RoutesBuilder) throws {

        let solutions = routes.grouped("task-solutions")
        let solution = solutions.grouped(TaskSolution.parameter)

        register(create: create(on:), router: solutions)
        register(update: update(on:), router: solutions, parameter: TaskSolution.self)
        register(delete: solutions, parameter: TaskSolution.self)

        solution.post("upvote", use: self.upvote(on: ))
        solution.post("revoke-vote", use: self.revokeVote(on: ))
        solution.post("approve", use: self.approve(on: ))

        routes.get("tasks", GenericTask.parameter, "solutions", use: solutionsForTask(on:))
    }
}
