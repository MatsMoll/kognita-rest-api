import Vapor
import KognitaCore

extension Task: Parameter {}
extension NoData: Content {}
extension TaskDiscussion: Content {}

public protocol TaskDiscussionAPIControlling: CreateModelAPIController, UpdateModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Update.Response>
    func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion]>
    func getDiscussionsForUser(on req: Request) throws -> EventLoopFuture<[TaskDiscussion]>
}

extension TaskDiscussionAPIControlling {

    public func boot(router: Router) throws {
        let discussion = router.grouped("task-discussion")
        register(create: create(on:), router: discussion)
        register(update: update(on:), router: discussion, parameter: TaskDiscussion.self)

        router.get("tasks", Task.parameter, "discussions", use: self.get(discussions: ))
        discussion.get("user", use: self.getDiscussionsForUser(on: ))
    }
}
