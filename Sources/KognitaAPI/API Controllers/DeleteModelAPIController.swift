import Vapor
import KognitaCore

public protocol DeleteModelAPIController {
    associatedtype Model: ModelParameterRepresentable
    associatedtype Repository: DeleteModelRepository

    static func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus>

    func register(delete router: Router)
}

extension DeleteModelAPIController {
    public func register(delete router: Router) {
        router.delete(Model.parameter, use: Self.delete)
    }
}

extension DeleteModelAPIController where
    Repository.Model == Model,
    Model.ParameterModel == Model {
    public static func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.authenticated(User.self)

        return req.parameters
            .model(Model.self, on: req)
            .flatMap { model in

                try Repository.delete(model: model, by: user, on: req)
                    .transform(to: .ok)
        }
    }
}
