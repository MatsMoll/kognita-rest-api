import Vapor
import FluentPostgreSQL
import KognitaCore

public protocol MultipleChoiseTaskAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: MultipleChoiseTaskRepository,
    UpdateData        == MultipleChoiceTask.Update.Data,
    UpdateResponse    == MultipleChoiceTask.Update.Response,
    CreateData        == MultipleChoiceTask.Create.Data,
    CreateResponse    == MultipleChoiceTask.Create.Response,
    Model             == TaskDiscussion {}

extension MultipleChoiseTaskAPIControlling {

    public func boot(router: Router) {
        let multiple = router.grouped("tasks/multiple-choise")

        register(create: multiple)
        register(update: multiple)
        register(delete: multiple)
    }
}
