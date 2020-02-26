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
{}

extension TaskDiscussionAPIControlling {

    public func boot(router: Router) throws {
        let discussion = router.grouped("task-discussion")
        register(create: discussion)
        register(update: discussion)
    }
}
