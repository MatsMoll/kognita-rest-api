import Vapor
import KognitaCore

public protocol RetriveModelAPIController {

    func register<Model: ModelParameterRepresentable, Response: Content>(retrive: @escaping (Request) throws -> EventLoopFuture<Response>, router: RoutesBuilder, parameter: Model.Type)
}

extension RetriveModelAPIController {
    public func register<Model: ModelParameterRepresentable, Response: Content>(retrive: @escaping (Request) throws -> EventLoopFuture<Response>, router: RoutesBuilder, parameter: Model.Type) {
        router.get(Model.parameter, use: retrive)
    }
}

//extension Request {
//    public func retrive<Model: ModelParameterRepresentable, Response: Content>(with repository: @escaping (Model.ID, Error) throws -> EventLoopFuture<Response>, parameter: Model.Type) throws -> EventLoopFuture<Response> {
//        try repository(parameters.get(Model.self), Abort(.badRequest))
//    }
//}
