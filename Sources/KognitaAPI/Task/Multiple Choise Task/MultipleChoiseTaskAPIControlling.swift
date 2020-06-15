import Vapor
import FluentPostgreSQL
import KognitaCore

public protocol MultipleChoiseTaskAPIControlling: CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask.Update.Response>
}

extension MultipleChoiseTaskAPIControlling {

    public func boot(router: Router) {
        let multiple = router.grouped("tasks/multiple-choise")

        register(create: create(on:), router: multiple)
        register(update: update(on:), router: multiple, parameter: MultipleChoiceTask.self)
        register(delete: multiple, parameter: MultipleChoiceTask.self)
    }
}
