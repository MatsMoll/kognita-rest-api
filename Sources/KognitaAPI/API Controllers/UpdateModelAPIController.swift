import Vapor
import KognitaCore

public protocol UpdateModelAPIController {

    func register<Model: ModelParameterRepresentable, R: Content>(update: @escaping (Request) throws -> EventLoopFuture<R>, router: RoutesBuilder, parameter: Model.Type)
}

extension UpdateModelAPIController {
    public func register<Model: ModelParameterRepresentable, R: Content>(update: @escaping (Request) throws -> EventLoopFuture<R>, router: RoutesBuilder, parameter: Model.Type) {
        router.put(Model.parameter, use: update)
    }
}

//extension Request {
//    func update<D: Decodable, P: ModelParameterRepresentable, R: Content>(with repository: @escaping (P.ID, D, User) throws -> EventLoopFuture<R>, parameter: P.Type) throws -> EventLoopFuture<R> {
//
//        let user = try auth.require(User.self)
//        let id = try parameters.get(parameter)
//
//        return try repository(id, try content.decode(D.self), user)
//    }
//}
