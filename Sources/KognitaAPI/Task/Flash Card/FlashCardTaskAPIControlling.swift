import Vapor
import KognitaCore

public protocol FlashCardTaskAPIControlling: CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<TypingTask.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<TypingTask.Update.Response>

    func createDraft(on req: Request) throws -> EventLoopFuture<Task.ID>
}

extension FlashCardTaskAPIControlling {

    public func boot(routes: RoutesBuilder) throws {
        let flashCard = routes.grouped("tasks", "flash-card")
        register(create: create(on:), router: flashCard)
        register(update: update(on:), router: flashCard, parameter: TypingTask.self)
        register(delete: flashCard, parameter: TypingTask.self)
        flashCard.post("draft", use: createDraft(on:))
    }
}
