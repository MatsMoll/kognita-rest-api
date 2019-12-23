import Vapor
import KognitaCore

public protocol DeleteModelAPIController {
    associatedtype Model: Parameter
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
    Model.ResolvedParameter == EventLoopFuture<Model>
{
    public static func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.authenticated(User.self)

        return try req.parameters
            .next(Model.self)
            .flatMap { model in

                try Repository.delete(model: model, by: user, on: req)
                    .transform(to: .ok)
        }
    }
}
