import Vapor
import KognitaCore

extension TaskDiscussionResponse.Create.Response: Content {}
extension TaskDiscussion: ModelParameterRepresentable {}
extension TaskDiscussionResponse: Content {}

public protocol TaskDiscussionResponseAPIControlling: CreateModelAPIController,
    RouteCollection
    where
    Repository: TaskDiscussionRepositoring,
    CreateData        == TaskDiscussionResponse.Create.Data,
    CreateResponse    == TaskDiscussionResponse.Create.Response {
    func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussionResponse]>
}

extension TaskDiscussionResponseAPIControlling {

    public func boot(router: Router) throws {
        let discussionResponse = router.grouped("task-discussion-response")
        register(create: discussionResponse)

        router.get("task-discussions", TaskDiscussion.parameter, "responses", use: self.get(responses: ))
    }
}
