import Vapor
import KognitaCore

extension Subtopic: ModelParameterRepresentable {}

public protocol SubtopicAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RouteCollection
    where
    Repository: SubtopicRepositoring,
    UpdateData        == Subtopic.Update.Data,
    UpdateResponse    == Subtopic.Update.Response,
    CreateData        == Subtopic.Create.Data,
    CreateResponse    == Subtopic.Create.Response,
    Model             == Subtopic,
    ModelResponse     == Subtopic {
    func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]>
}

extension SubtopicAPIControlling {
    public func boot(router: Router) throws {

        let subtopics = router.grouped("subtopics")

        register(create: subtopics)
        register(delete: subtopics)
        register(update: subtopics)
        register(retrive: subtopics)

        router.get("topics", Topic.parameter, "subtopics", use: self.getAllIn(topic: ))
    }
}
