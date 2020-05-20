import Vapor
import KognitaCore

public protocol RetriveModelAPIController {

    associatedtype Model: ModelParameterRepresentable
    associatedtype ModelResponse: Content

    static func retrive(on req: Request) throws -> EventLoopFuture<ModelResponse>

    func register(retrive router: Router)
}

extension RetriveModelAPIController {
    public func register(retrive router: Router) {
        router.get(Model.parameter, use: Self.retrive)
    }
}

extension RetriveModelAPIController where
    Model == ModelResponse,
    Model.ParameterModel == Model {
    public static func retrive(on req: Request) throws -> EventLoopFuture<ModelResponse> {
        req.parameters.model(Model.self, on: req)
    }
}
