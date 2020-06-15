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
    public func boot(router: Router) {

        let users = router.grouped("users")

        // public routes
        register(create: create(on:), router: users)

        users.post(User.parameter, "verify", use: self.verify(on: ))
        users.post("send-reset-mail", use: self.startResetPassword)
        users.post("reset-password", use: self.resetPassword)

        // basic / password auth protected routes
        let basic = router.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
        basic.post("users/login", use: self.login)
    }
}
