import Vapor
import KognitaCore

public protocol RetriveModelAPIController {

    associatedtype Model: Parameter
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
    Model.ResolvedParameter == EventLoopFuture<Model>
{
    public static func retrive(on req: Request) throws -> EventLoopFuture<ModelResponse> {
        try req.parameters.next(Model.self)
    }
}
