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
    
    /// Returns the logged in user
    /// - Parameter req: The HTTP request
    func user(on req: Request) throws -> EventLoopFuture<User>
    
    /// Use the Feide service to login
    /// - Parameter req: The HTTP request
    func feideLogin(on req: Request) -> Response
    
    /// Handels the callback request when authenticating with Feide
    /// - Parameter req: The HTTP request that is sendt
    func handleFeideCallback(on req: Request) throws -> EventLoopFuture<Response>
}

extension UserAPIControlling {
    public func boot(routes: RoutesBuilder) throws {

        let users = routes.grouped("users")

        // public routes
        register(create: create(on:), router: users)

        users.grouped(User.bearerAuthMiddleware()).get(use: user(on: ))
        users.post(User.parameter, "verify", use: self.verify(on: ))
        users.post("send-reset-mail", use: self.startResetPassword)
        users.post("reset-password", use: self.resetPassword)

        // basic / password auth protected routes
        let basic = users.grouped(User.basicAuthMiddleware())
        basic.post("login", use: self.login)
        
        users.get("login", "feide", use: self.feideLogin(on:))
        routes.grouped(User.sessionAuthMiddleware()).get("callback", use: self.handleFeideCallback(on:))
    }
}
