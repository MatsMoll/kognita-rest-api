import Vapor
import KognitaCore

public protocol SubtopicAPIControlling:
    CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RouteCollection
    where
    Repository: SubtopicRepositoring,
    UpdateData        == Subtopic.Edit.Data,
    UpdateResponse    == Subtopic.Edit.Response,
    CreateData        == Subtopic.Create.Data,
    CreateResponse    == Subtopic.Create.Response,
    Model             == Subtopic
{
    static func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]>
}

extension SubtopicAPIControlling {
    public func boot(router: Router) throws {

        let subtopics = router.grouped("subtopics")

        register(create:    subtopics)
        register(delete:    subtopics)
        register(update:    subtopics)
        register(retrive:   subtopics)

        router.get("topics", Topic.parameter, "subtopics", use: Self.getAllIn(topic: ))
    }
}
