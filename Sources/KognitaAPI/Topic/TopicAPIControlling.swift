import FluentPostgreSQL
import Vapor
import KognitaCore

extension Topic: ModelParameterRepresentable {}

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
    UpdateData      == Topic.Update.Data,
    UpdateResponse  == Topic.Update.Response,
    ModelResponse   == Topic {
    func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]>
}

extension TopicAPIControlling {
    public func boot(router: Router) {

        let topics = router.grouped("topics")

        router.get("subjects", Subject.parameter, "topics", use: self.getAllIn(subject: ))

        register(create: topics)
        register(delete: topics)
        register(update: topics)
        register(retrive: topics)
        register(retriveAll: topics)
    }
}
