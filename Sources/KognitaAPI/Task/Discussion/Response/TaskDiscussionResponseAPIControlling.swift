import Vapor
import KognitaCore

public protocol TaskDiscussionResponseAPIControlling: CreateModelAPIController,
    RouteCollection
    where
    Repository: TaskDiscussionRepositoring,
    CreateData        == TaskDiscussion.Pivot.Response.Create.Data,
    CreateResponse    == TaskDiscussion.Pivot.Response.Create.Response {
    static func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussion.Pivot.Response.Details]>
}

extension TaskDiscussionResponseAPIControlling {

    public func boot(router: Router) throws {
        let discussionResponse = router.grouped("task-discussion-response")
        register(create: discussionResponse)

        router.get("task-discussions", TaskDiscussion.parameter, "responses", use: Self.get(responses: ))
    }
}
