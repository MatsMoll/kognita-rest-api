import Vapor
import KognitaCore

extension TaskDiscussionResponse.Create.Response: Content {}
extension TaskDiscussion: ModelParameterRepresentable {}
extension TaskDiscussionResponse: Content {}

public protocol TaskDiscussionResponseAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<TaskDiscussionResponse.Create.Response>
    func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussionResponse]>
    func setRecentlyVisited(on req: Request) throws -> EventLoopFuture<Bool>
}

extension TaskDiscussionResponseAPIControlling {

    public func boot(routes: RoutesBuilder) throws {
        let discussionResponse = routes.grouped("task-discussion-response")
        register(create: create(on:), router: discussionResponse)

        routes.get("task-discussions", TaskDiscussion.parameter, "responses", use: self.get(responses: ))
    }
}
