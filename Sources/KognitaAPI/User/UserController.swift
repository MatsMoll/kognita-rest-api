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
public final class UserAPIController<Repository: UserRepository>: UserAPIControlling {

    public enum Errors: Error {
        case userNotFound
    }

    /// Logs a user in, returning a token for accessing protected endpoints.
    public static func login(_ req: Request) throws -> EventLoopFuture<UserToken> {
        // get user auth'd by basic auth middleware
        let user = try req.requireAuthenticated(User.self)

        return try User.DatabaseRepository
            .login(with: user, conn: req)
    }

    /// Creates a new user.
    public static func create(_ req: Request) throws -> EventLoopFuture<User.Response> {
        // decode request content
        return try req.content
            .decode(User.Create.Data.self)
            .flatMap { content in
                try User.DatabaseRepository
                    .create(from: content, by: nil, on: req)
        }
    }


    public static func startResetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        return try req.content
            .decode(User.ResetPassword.Email.self)
            .flatMap { email in

                Repository
                    .first(with: email.email, on: req)
                    .flatMap { user in

                        guard let user = user else {
                            return req.future(.ok)
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
                                    .transform(to: .ok)
                        }
                }
        }
    }

    public static func resetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return try req.content
            .decode(User.ResetPassword.Token.Data.self)
            .flatMap { token in

                try req.content
                    .decode(User.ResetPassword.Data.self)
                    .flatMap { data in

                        try User.ResetPassword.Token.Repository
                            .reset(to: data, with: token.token, on: req)
                            .transform(to: .ok)
                }
        }
    }
}

extension User {
    public typealias DefaultAPIController = UserAPIController<User.DatabaseRepository>
}
