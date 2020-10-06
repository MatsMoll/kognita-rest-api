import Vapor
import KognitaCore

public protocol CreateModelAPIController {

    func register<R: Content>(create: @escaping (Request) throws -> EventLoopFuture<R>, router: RoutesBuilder)
}

extension CreateModelAPIController {
    public func register<R: Content>(create: @escaping (Request) throws -> EventLoopFuture<R>, router: RoutesBuilder) {
        router.post(use: create)
    }
}

extension Request {
    func create<CreateData: Decodable, CreateResponse: Content>(in repository: @escaping (CreateData, User?) throws -> EventLoopFuture<CreateResponse>) throws -> EventLoopFuture<CreateResponse> {
        return try repository(content.decode(), auth.require())
    }

    func create<CreateData: Decodable, CreateResponse: Content>(in repository: @escaping (CreateData, User) throws -> EventLoopFuture<CreateResponse>) throws -> EventLoopFuture<CreateResponse> {
        return try repository(content.decode(), auth.require())
    }
}
