import Vapor
import KognitaCore

public protocol TaskDiscussionAPIControlling:
    CreateModelAPIController,
    UpdateModelAPIController,
    RouteCollection
    where
    Repository: TaskDiscussionRepositoring,
    UpdateData        == TaskDiscussion.Update.Data,
    UpdateResponse    == TaskDiscussion.Update.Response,
    CreateData        == TaskDiscussion.Create.Data,
    CreateResponse    == TaskDiscussion.Create.Response,
    Model             == TaskDiscussion
{
    static func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion.Details]>
}

extension TaskDiscussionAPIControlling {

    public func boot(router: Router) throws {
        let discussion = router.grouped("task-discussion")
        register(create: discussion)
        register(update: discussion)

        router.get("tasks", Task.parameter, "discussions", use: Self.get(discussions: ))
    }
}
