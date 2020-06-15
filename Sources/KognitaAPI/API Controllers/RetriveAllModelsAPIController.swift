import Vapor
import KognitaCore

public protocol RetriveAllModelsAPIController {
    func register<Response: Content>(retriveAll: @escaping (Request) throws -> EventLoopFuture<[Response]>, router: Router)
}

extension RetriveAllModelsAPIController {
    public func register<Response: Content>(retriveAll: @escaping (Request) throws -> EventLoopFuture<[Response]>, router: Router) {
        router.get("/", use: retriveAll)
    }
}
