import Vapor
import KognitaCore

public protocol MultipleChoiseTaskAPIControlling: CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask.Update.Response>
}

extension MultipleChoiseTaskAPIControlling {

    public func boot(routes: RoutesBuilder) throws {
        let multiple = routes.grouped("tasks", "multiple-choise")

        register(create: create(on:), router: multiple)
        register(update: update(on:), router: multiple, parameter: MultipleChoiceTask.self)
        register(delete: multiple, parameter: MultipleChoiceTask.self)
    }
}
