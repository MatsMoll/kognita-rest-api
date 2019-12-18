import Crypto
import Vapor
import FluentPostgreSQL
import KognitaCore
import Mailgun

public protocol ResetPasswordMailRenderable: Service {
    func render(with token: User.ResetPassword.Token.Create.Response, for user: User) throws -> String
}

extension User.ResetPassword {
    public struct Email : Content {
        public let email: String
    }
}

/// Creates new users and logs them in.
public final class UserController: RouteCollection {

    public enum Errors: Error {
        case userNotFound
    }

    public func boot(router: Router) {

        let users = router.grouped("users")

        // public routes
        router.post("users", use: UserController.create)
        users.post("send-reset-mail", use: UserController.startResetPassword)
        users.post("reset-password", use: UserController.resetPassword)

        // basic / password auth protected routes
        let basic = router.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
        basic.post("users/login", use: UserController.login)

//        let auth = basic.grouped(User.authSessionsMiddleware())
//        auth.get("users/overview", use: UserController.getAllUsers)
        }

    static let shared = UserController()

    /// Logs a user in, returning a token for accessing protected endpoints.
    public static func login(_ req: Request) throws -> EventLoopFuture<UserToken> {
        // get user auth'd by basic auth middleware
        let user = try req.requireAuthenticated(User.self)

        return try User.Repository
            .login(with: user, conn: req)
    }

    /// Creates a new user.
    public static func create(_ req: Request) throws -> EventLoopFuture<User.Response> {
        // decode request content
        return try req.content
            .decode(User.Create.Data.self)
            .flatMap { content in
                try User.Repository
                    .create(from: content, by: nil, on: req)
        }
    }

    public static func getAllUsers(on req: Request) throws -> EventLoopFuture<[User.Response]> {
        let user = try req.requireAuthenticated(User.self)
        guard user.isCreator else {
            throw Abort(.forbidden)
        }
        return User.Repository
            .getAll(on: req)
    }

    public static func startResetPassword(on req: Request) throws -> EventLoopFuture<Response> {

        try req.content
            .decode(User.ResetPassword.Email.self)
            .flatMap { email in

                User.Repository
                    .first(where: \User.email == email.email, on: req)
                    .flatMap { user in

                        guard let user = user else {
                            return req.future(Response(using: req))
                        }
                        return try User.ResetPassword.Token.Repository
                            .create(by: user, on: req)
                            .flatMap { token in

                                let renderer = try req.make(ResetPasswordMailRenderable.self)
                                let mailgun = try req.make(Mailgun.self)

                                let mail = try Mailgun.Message(
                                    from:       "kontakt@kognita.no",
                                    to:         email.email,
                                    subject:    "Kognita - Gjenopprett Passord",
                                    text:       "",
                                    html:       renderer.render(with: token, for: user)
                                )
                                return try mailgun.send(mail, on: req)
                                    .transform(to: Response(using: req))
                        }
                }
        }
    }

    public static func resetPassword(on req: Request) throws -> EventLoopFuture<Response> {
        return try req.content
            .decode(User.ResetPassword.Token.Data.self)
            .flatMap { token in

                try req.content
                    .decode(User.ResetPassword.Data.self)
                    .flatMap { data in

                        try User.ResetPassword.Token.Repository
                            .reset(to: data, with: token.token, on: req)
                            .transform(to: Response(using: req))
                }
        }
    }
}
