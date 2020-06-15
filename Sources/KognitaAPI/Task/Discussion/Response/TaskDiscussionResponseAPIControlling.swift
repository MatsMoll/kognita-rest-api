import Vapor
import KognitaCore

extension TaskDiscussionResponse.Create.Response: Content {}
extension TaskDiscussion: ModelParameterRepresentable {}
extension TaskDiscussionResponse: Content {}

public protocol TaskDiscussionResponseAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<TaskDiscussionResponse.Create.Response>
    func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussionResponse]>
}

extension TaskDiscussionResponseAPIControlling {

    public func boot(router: Router) throws {
        let discussionResponse = router.grouped("task-discussion-response")
        register(create: create(on:), router: discussionResponse)

        router.get("task-discussions", TaskDiscussion.parameter, "responses", use: self.get(responses: ))
    }
}
