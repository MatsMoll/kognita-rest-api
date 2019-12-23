import Vapor
import KognitaCore

public protocol RetriveAllModelsAPIController {

    associatedtype ModelResponse: Content
    associatedtype Repository

    static func retriveAll(on req: Request) throws -> EventLoopFuture<[ModelResponse]>

    func register(retriveAll router: Router)
}

extension RetriveAllModelsAPIController {
    public func register(retriveAll router: Router) {
        router.get("/", use: Self.retriveAll)
    }
}

extension RetriveAllModelsAPIController where
    Repository: RetriveAllModelsRepository,
    Repository.ResponseModel == ModelResponse
{
    public static func retriveAll(on req: Request) throws -> EventLoopFuture<[ModelResponse]> {
        return try Repository.all(on: req)
    }
}
