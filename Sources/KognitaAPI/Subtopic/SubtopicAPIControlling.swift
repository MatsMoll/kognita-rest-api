import Vapor
import KognitaCore

extension Subtopic: ModelParameterRepresentable {}

public protocol SubtopicAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<Subtopic.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<Subtopic.Update.Response>
    func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]>
    func retrive(on req: Request) throws -> EventLoopFuture<Subtopic>
}

extension SubtopicAPIControlling {
    public func boot(routes: RoutesBuilder) throws {

        let subtopics = routes.grouped("subtopics")

        register(create: create(on: ), router: subtopics)
        register(update: update(on:), router: subtopics, parameter: Subtopic.self)
        register(delete: subtopics, parameter: Subtopic.self)
        register(retrive: retrive(on:), router: subtopics, parameter: Subtopic.self)

        routes.get("topics", Topic.parameter, "subtopics", use: self.getAllIn(topic: ))
    }
}
