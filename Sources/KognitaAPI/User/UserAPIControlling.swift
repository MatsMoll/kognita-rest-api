import Vapor
import KognitaCore
import Crypto

extension User: Content {}
extension User: ModelParameterRepresentable {}

public protocol UserAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<User.Create.Response>
    func login(_ req: Request) throws -> EventLoopFuture<User.Login.Token>
    func startResetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func resetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func verify(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension UserAPIControlling {
    public func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped("users")

        // public routes
        register(create: create(on:), router: users)

        users.post(User.parameter, "verify", use: self.verify(on: ))
        users.post("send-reset-mail", use: self.startResetPassword)
        users.post("reset-password", use: self.resetPassword)

        // basic / password auth protected routes
        let basic = users.grouped(User.basicAuthMiddleware())
        basic.post("login", use: self.login)
    }
}
