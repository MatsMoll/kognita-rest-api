import FluentPostgreSQL
import Vapor
import KognitaCore

public protocol TopicAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection
    where
    Repository: TopicRepository,
    Model           == Topic,
    CreateData      == Topic.Create.Data,
    CreateResponse  == Topic.Create.Response,
    UpdateData      == Topic.Edit.Data,
    UpdateResponse  == Topic.Edit.Response,
    ModelResponse   == Topic {
    static func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]>
}

extension TopicAPIControlling {
    public func boot(router: Router) {

        let topics = router.grouped("topics")

        router.get("subjects", Subject.parameter, "topics", use: Self.getAllIn(subject: ))

        register(create: topics)
        register(delete: topics)
        register(update: topics)
        register(retrive: topics)
        register(retriveAll: topics)
    }
}
