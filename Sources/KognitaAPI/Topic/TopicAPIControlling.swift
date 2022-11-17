import Vapor
import KognitaCore

extension Topic: ModelParameterRepresentable {}
extension Topic.Export: Content {}

public protocol TopicAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection {
    func save(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
    func create(on req: Request) throws -> EventLoopFuture<Topic.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<Topic.Update.Response>
    func retriveAll(_ req: Request) throws -> EventLoopFuture<[Topic]>
    func retrive(_ req: Request) throws -> EventLoopFuture<Topic>
    func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]>
    func export(topic req: Request) throws -> EventLoopFuture<Topic.Export>
    func importSubtopics(req: Request) throws -> EventLoopFuture<HTTPResponseStatus>
}

extension TopicAPIControlling {
    public func boot(routes: RoutesBuilder) throws {

        let topics = routes.grouped("topics")

        routes.get("subjects", Subject.parameter, "topics", use: self.getAllIn(subject: ))
        routes.put("subjects", Subject.parameter, "topics", use: self.save(on: ))

        register(create: create(on:), router: topics)
        register(update: update(on:), router: topics, parameter: Topic.self)
        register(retrive: retrive(_:), router: topics, parameter: Topic.self)
        register(delete: topics, parameter: Topic.self)
        register(retriveAll: retriveAll(_:), router: topics)

        topics.on(.GET, Topic.parameter, "export", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: self.export(topic: ))
        topics.on(.POST, Topic.parameter, "import", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: importSubtopics(req: ))
    }
}
