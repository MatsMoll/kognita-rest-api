import Vapor
import KognitaCore

public protocol UpdateModelAPIController {
    associatedtype UpdateData: Codable
    associatedtype UpdateResponse: Content
    associatedtype Model: ModelParameterRepresentable
    associatedtype Repository: UpdateModelRepository

    var repository: Repository { get }

    func update(on req: Request) throws -> EventLoopFuture<UpdateResponse>

    func register(update route: Router)
}

extension UpdateModelAPIController {
    public func register(update router: Router) {
        router.put(Model.parameter, use: self.update)
    }
}

extension UpdateModelAPIController where
    Repository.UpdateData       == UpdateData,
    Repository.UpdateResponse   == UpdateResponse,
    Repository.ID               == Model.ID {
    public func update(on req: Request) throws -> EventLoopFuture<UpdateResponse> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(UpdateData.self)
            .flatMap { data in

                try self.repository.updateModelWith(
                    id: req.parameters.modelID(Model.self),
                    to: data,
                    by: user
                )
        }
    }
}
