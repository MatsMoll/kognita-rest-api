import Vapor
import KognitaCore

public protocol UpdateModelAPIController {
    associatedtype UpdateData: Codable
    associatedtype UpdateResponse: Content
    associatedtype Model: ModelParameterRepresentable
    associatedtype Repository: UpdateModelRepository

    static func update(on req: Request) throws -> EventLoopFuture<UpdateResponse>

    func register(update route: Router)
}

extension UpdateModelAPIController {
    public func register(update router: Router) {
        router.put(Model.parameter, use: Self.update)
    }
}

extension UpdateModelAPIController where
    Repository.UpdateData       == UpdateData,
    Repository.UpdateResponse   == UpdateResponse,
    Repository.Model            == Model,
    Model.ParameterModel        == Model
{
    public static func update(on req: Request) throws -> EventLoopFuture<UpdateResponse> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(UpdateData.self)
            .flatMap { data in

                req.parameters
                    .model(Model.self, on: req)
                    .flatMap { model in

                        try Repository.update(model: model, to: data, by: user, on: req)
                }
        }
    }
}
