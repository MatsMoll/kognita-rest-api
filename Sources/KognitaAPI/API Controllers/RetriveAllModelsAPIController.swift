import Vapor
import KognitaCore

public protocol RetriveAllModelsAPIController {
    func register<Response: Content>(retriveAll: @escaping (Request) throws -> EventLoopFuture<[Response]>, router: RoutesBuilder)
}

extension RetriveAllModelsAPIController {
    public func register<Response: Content>(retriveAll: @escaping (Request) throws -> EventLoopFuture<[Response]>, router: RoutesBuilder) {
        router.get(use: retriveAll)
    }
}
