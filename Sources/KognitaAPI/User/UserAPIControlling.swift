import Vapor
import KognitaCore
import Crypto

public protocol UserAPIControlling: CreateModelAPIController,
    RouteCollection
    where
    Repository: UserRepository,
    CreateData      == User.Create.Data,
    CreateResponse  == User.Create.Response {
    static func login(_ req: Request) throws -> EventLoopFuture<User.Login.Token>
    static func startResetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func resetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func verify(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension UserAPIControlling {
    public func boot(router: Router) {

        let users = router.grouped("users")

        // public routes
        register(create: users)

        users.post(User.parameter, "verify", use: Self.verify(on: ))
        users.post("send-reset-mail", use: Self.startResetPassword)
        users.post("reset-password", use: Self.resetPassword)

        // basic / password auth protected routes
        let basic = router.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
        basic.post("users/login", use: Self.login)
    }
}
