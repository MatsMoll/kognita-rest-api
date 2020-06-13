import Vapor
import KognitaCore

extension Task: Parameter {}
extension NoData: Content {}
extension TaskDiscussion: Content {}

public protocol TaskDiscussionAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    RouteCollection
    where
    Repository: TaskDiscussionRepositoring,
    UpdateData        == TaskDiscussion.Update.Data,
    UpdateResponse    == TaskDiscussion.Update.Response,
    CreateData        == TaskDiscussion.Create.Data,
    CreateResponse    == TaskDiscussion.Create.Response,
    Model             == TaskDiscussion {
    func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion]>
    func getDiscussionsForUser(on req: Request) throws -> EventLoopFuture<[TaskDiscussion]>
}

extension TaskDiscussionAPIControlling {

    public func boot(router: Router) throws {
        let discussion = router.grouped("task-discussion")
        register(create: discussion)
        register(update: discussion)

        router.get("tasks", Task.parameter, "discussions", use: self.get(discussions: ))
        discussion.get("user", use: self.getDiscussionsForUser(on: ))
    }
}
