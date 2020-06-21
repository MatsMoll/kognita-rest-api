import Vapor
import FluentPostgreSQL
import KognitaCore
import Mailgun

public protocol ResetPasswordMailRenderable: Service {
    func render(with token: User.ResetPassword.Token.Data, for user: User) throws -> String
}

extension User.ResetPassword {
    public struct Email: Content {
        public let email: String
    }
}

/// Creates new users and logs them in.
public struct UserAPIController<Repository: UserRepository>: UserAPIControlling {

    public enum Errors: Error {
        case userNotFound
    }

    let repositories: RepositoriesRepresentable

    public var repository: UserRepository { repositories.userRepository }

    /// Logs a user in, returning a token for accessing protected endpoints.
    public func login(_ req: Request) throws -> EventLoopFuture<User.Login.Token> {
        // get user auth'd by basic auth middleware
        try repository.login(with: req.requireAuthenticated())
    }

    /// Creates a new user.
    public func create(on req: Request) throws -> EventLoopFuture<User> {
        // decode request content
        return try req.content
            .decode(User.Create.Data.self)
            .flatMap { content in
                try self.repository.create(from: content, by: nil)
        }
        .flatMap { user in
            try self.sendVerifyEmail(to: user, on: req)
                .transform(to: user)
        }
    }

    /// Sends verification email and set this as a scheduled job, waiting 30 seconds before sending the email.
    func sendVerifyEmail(to user: User, on req: Request) throws -> EventLoopFuture<Void> {
        let jobQueue = try req.make(JobQueueable.self)
        jobQueue.scheduleFutureJob(after: .seconds(30)) { (container, conn) -> EventLoopFuture<Void> in
            let sender = try container.make(VerifyEmailSendable.self)
            return try self.repository.verifyToken(for: user.id)
                .flatMap { token in
                    try sender.sendEmail(with: token.content(with: user.email), on: container)
            }
        }
        return req.future()
    }

    public func startResetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        return try req.content
            .decode(User.ResetPassword.Email.self)
            .flatMap { email in

                let userEmail = email.email.lowercased()

                return self.repository
                    .first(with: userEmail)
                    .flatMap { user in

                        guard let user = user else {
                            return req.future(.ok)
                        }
                        return try self.repository
                            .startReset(for: user)
                            .flatMap { token in

                                let renderer = try req.make(ResetPasswordMailRenderable.self)
                                let mailgun = try req.make(MailgunProvider.self)

                                let mail = try Mailgun.Message(
                                    from: "kontakt@kognita.no",
                                    to: userEmail,
                                    subject: "Kognita - Gjenopprett Passord",
                                    text: "",
                                    html: renderer.render(with: token, for: user)
                                )
                                return try mailgun.send(mail, on: req)
                                    .transform(to: .ok)
                        }
                }
        }
    }

    public func resetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {


        return try req.content
            .decode(User.ResetPassword.Token.Data.self)
            .flatMap { token in

                try req.content
                    .decode(User.ResetPassword.Data.self)
                    .flatMap { data in

                        try self.repository
                            .reset(to: data, with: token.token)
                            .transform(to: .ok)
                }
        }
    }

    public func verify(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        // For Web
        if let request = try? req.query.decode(User.VerifyEmail.Request.self) {

            return try repository.find(req.parameters.modelID(User.self), or: Abort(.badRequest))
                .flatMap { user in

                    try self.repository.verify(user: user, with: request)
                        .transform(to: .ok)
            }
        } else {
            // For API
            return try req.content
                .decode(User.VerifyEmail.Request.self)
                .flatMap { request in

                    try self.repository.find(req.parameters.modelID(User.self), or: Abort(.badRequest))
                        .flatMap { user in

                            try self.repository.verify(user: user, with: request)
                                .transform(to: .ok)
                    }
            }
        }
    }
}

extension User {
    public typealias DefaultAPIController = UserAPIController<User.DatabaseRepository>
}
