import Vapor
import KognitaCore

public protocol RetriveModelAPIController {

    associatedtype Model: ModelParameterRepresentable
    associatedtype ModelResponse: Content
    associatedtype Repository: RetriveModelRepository

    var repository: Repository { get }

    func retrive(on req: Request) throws -> EventLoopFuture<ModelResponse>

    func register(retrive router: Router)
}

extension RetriveModelAPIController {
    public func register(retrive router: Router) {
        router.get(Model.parameter, use: self.retrive)
    }
}

extension RetriveModelAPIController where
    Model == ModelResponse,
    Repository.Model == Model {
    public func retrive(on req: Request) throws -> EventLoopFuture<ModelResponse> {
        try repository.find(req.parameters.modelID(Model.self), or: Abort(.badRequest))
    }
}
