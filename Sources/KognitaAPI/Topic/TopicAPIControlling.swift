import Vapor
import KognitaCore

extension Topic: ModelParameterRepresentable {}

public protocol TopicAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<Topic.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<Topic.Update.Response>
    func retriveAll(_ req: Request) throws -> EventLoopFuture<[Topic]>
    func retrive(_ req: Request) throws -> EventLoopFuture<Topic>
    func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]>
}

extension TopicAPIControlling {
    public func boot(routes: RoutesBuilder) throws {

        let topics = routes.grouped("topics")

        routes.get("subjects", Subject.parameter, "topics", use: self.getAllIn(subject: ))

        register(create: create(on:), router: topics)
        register(update: update(on:), router: topics, parameter: Topic.self)
        register(retrive: retrive(_:), router: topics, parameter: Topic.self)
        register(delete: topics, parameter: Topic.self)
        register(retriveAll: retriveAll(_:), router: topics)
    }
}
