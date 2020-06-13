import Vapor
import KognitaCore

public protocol RetriveAllModelsAPIController {

    associatedtype ModelResponse: Content
    associatedtype Repository: RetriveAllModelsRepository

    var repository: Repository { get }

    func retriveAll(on req: Request) throws -> EventLoopFuture<[ModelResponse]>

    func register(retriveAll router: Router)
}

extension RetriveAllModelsAPIController {
    public func register(retriveAll router: Router) {
        router.get("/", use: self.retriveAll)
    }
}

extension RetriveAllModelsAPIController where
    Repository.ResponseModel == ModelResponse {
    public func retriveAll(on req: Request) throws -> EventLoopFuture<[ModelResponse]> {
        return try repository.all()
    }
}
