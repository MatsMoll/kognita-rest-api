import Vapor
import KognitaCore

public protocol FlashCardTaskAPIControlling: CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<FlashCardTask.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<FlashCardTask.Edit.Response>
}

extension FlashCardTaskAPIControlling {

    public func boot(router: Router) throws {
        let flashCard = router.grouped("tasks/flash-card")
        register(create: create(on:), router: flashCard)
        register(update: update(on:), router: flashCard, parameter: TypingTask.self)
        register(delete: flashCard, parameter: TypingTask.self)
    }
}
