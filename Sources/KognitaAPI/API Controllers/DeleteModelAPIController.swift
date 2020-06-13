import Vapor
import KognitaCore

public protocol DeleteModelAPIController {
    associatedtype Model: ModelParameterRepresentable
    associatedtype Repository: DeleteModelRepository

    var repository: Repository { get }

    func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus>

    func register(delete router: Router)
}

extension DeleteModelAPIController {
    public func register(delete router: Router) {
        router.delete(Model.parameter, use: self.delete)
    }
}

extension DeleteModelAPIController where Repository.ID == Model.ID {
    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.authenticated(User.self)

        return try repository.deleteModelWith(
            id: req.parameters.modelID(Model.self),
            by: user
        )
        .transform(to: .ok)
    }
}
