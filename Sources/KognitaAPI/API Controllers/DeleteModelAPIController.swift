import Vapor
import KognitaCore

public protocol DeleteModelAPIController {

    func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus>

    func register<Model: ModelParameterRepresentable>(delete router: RoutesBuilder, parameter: Model.Type)
}

extension DeleteModelAPIController {
    public func register<Model: ModelParameterRepresentable>(delete router: RoutesBuilder, parameter: Model.Type) {
        router.delete(Model.parameter, use: self.delete)
    }
}

//extension Request {
//    func delete<Model: ModelParameterRepresentable>(with repository: @escaping (Model.ID, User?) throws -> EventLoopFuture<Void>, parameter: Model.Type) throws -> EventLoopFuture<HTTPStatus> {
//        return try repository(
//            parameters.get(Model.self),
//            auth.get()
//        )
//        .transform(to: .ok)
//    }
//}
