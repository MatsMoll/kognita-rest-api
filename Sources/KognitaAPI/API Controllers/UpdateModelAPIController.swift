import Vapor
import KognitaCore

public protocol UpdateModelAPIController {

    func register<Model: ModelParameterRepresentable, R: Content>(update: @escaping (Request) throws -> EventLoopFuture<R>, router: Router, parameter: Model.Type)
}

extension UpdateModelAPIController {
    public func register<Model: ModelParameterRepresentable, R: Content>(update: @escaping (Request) throws -> EventLoopFuture<R>, router: Router, parameter: Model.Type) {
        router.put(Model.parameter, use: update)
    }
}

//extension UpdateModelAPIController where
//    Repository.UpdateData       == UpdateData,
//    Repository.UpdateResponse   == UpdateResponse,
//    Repository.ID               == Model.ID {
//    public func update(on req: Request) throws -> EventLoopFuture<UpdateResponse> {
//
//        let user = try req.requireAuthenticated(User.self)
//
//        return try req.content
//            .decode(UpdateData.self)
//            .flatMap { data in
//
//                try self.repository.updateModelWith(
//                    id: req.parameters.modelID(Model.self),
//                    to: data,
//                    by: user
//                )
//        }
//    }
//}

extension Request {
    func update<D: Decodable, P: ModelParameterRepresentable, R: Content>(with repository: @escaping (P.ID, D, User) throws -> EventLoopFuture<R>, parameter: P.Type) throws -> EventLoopFuture<R> {

        let user = try requireAuthenticated(User.self)
        let id = try parameters.modelID(parameter)

        return try content
            .decode(D.self)
            .flatMap { data in
                try repository(id, data, user)
        }
    }
}
