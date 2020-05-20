import Vapor
import KognitaCore

public protocol FlashCardTaskAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: FlashCardTaskRepository,
    UpdateData        == FlashCardTask.Edit.Data,
    UpdateResponse    == FlashCardTask.Edit.Response,
    CreateData        == FlashCardTask.Create.Data,
    CreateResponse    == FlashCardTask.Create.Response,
    Model             == FlashCardTask {}

extension FlashCardTaskAPIControlling {

    public func boot(router: Router) throws {
        let flashCard = router.grouped("tasks/flash-card")
        register(create: flashCard)
        register(delete: flashCard)
        register(update: flashCard)
    }
}
