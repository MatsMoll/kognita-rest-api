import Vapor
import FluentPostgreSQL
import KognitaCore

public protocol MultipleChoiseTaskAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RouteCollection
    where
    Repository: MultipleChoiseTaskRepository,
    UpdateData        == MultipleChoiseTask.Edit.Data,
    UpdateResponse    == MultipleChoiseTask.Edit.Response,
    CreateData        == MultipleChoiseTask.Create.Data,
    CreateResponse    == MultipleChoiseTask.Create.Response,
    Model             == MultipleChoiseTask {}

extension MultipleChoiseTaskAPIControlling {

    public func boot(router: Router) {
        let multiple = router.grouped("tasks/multiple-choise")

        register(create: multiple)
        register(update: multiple)
        register(delete: multiple)
    }
}
