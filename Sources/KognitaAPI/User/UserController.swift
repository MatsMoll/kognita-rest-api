import Vapor
import KognitaCore
import Mailgun

public protocol ResetPasswordMailRenderable {
    func render(with token: User.ResetPassword.Token, for user: User) throws -> String
}

public struct ResetPasswordMailRenderableFactory {
    var make: ((Request) -> ResetPasswordMailRenderable)?
    public mutating func use(_ make: @escaping (Request) -> ResetPasswordMailRenderable) {
        self.make = make
    }
}

extension Application {
    private struct ResetPasswordMailRenderableKey: StorageKey {
        typealias Value = ResetPasswordMailRenderableFactory
    }

    public var resetPasswordRenderer: ResetPasswordMailRenderableFactory {
        get { self.storage[ResetPasswordMailRenderableKey.self] ?? .init() }
        set { self.storage[ResetPasswordMailRenderableKey.self] = newValue }
    }
}

extension Request {
    public var resetPasswordRenderer: ResetPasswordMailRenderable {
        self.application.resetPasswordRenderer.make!(self)
    }
}

extension User.ResetPassword {
    public struct Email: Content {
        public let email: String
    }
}

/// Creates new users and logs them in.
public struct UserAPIController: UserAPIControlling {

    public enum Errors: Error {
        case userNotFound
    }

    public func user(on req: Request) throws -> EventLoopFuture<User> {
        try req.eventLoop.future(req.auth.require(User.self))
    }

    /// Logs a user in, returning a token for accessing protected endpoints.
    public func login(_ req: Request) throws -> EventLoopFuture<User.Login.Token> {
        // get user auth'd by basic auth middleware
        let user: User = try req.auth.require()
        return req.repositories { repositories in
            try repositories.userRepository.login(with: user)
                .flatMap { token in
                    repositories.userRepository.logLogin(for: user, with: req.remoteAddress?.ipAddress)
                        .transform(to: token)
            }
        }
    }

    /// Creates a new user.
    public func create(on req: Request) throws -> EventLoopFuture<User> {
        // decode request content
        req.repositories { repositories in
            try repositories.userRepository.create(from: req.content.decode(User.Create.Data.self))
        }
        .flatMap { user in
            self.sendVerifyEmail(to: user, on: req)
                .transform(to: user)
        }
    }

    /// Sends verification email and set this as a scheduled job, waiting 30 seconds before sending the email.
    func sendVerifyEmail(to user: User, on req: Request) -> EventLoopFuture<Void> {
        req.repositories { repositories in
            repositories.userRepository
                .verifyToken(for: user.id)
        }
        .failableFlatMap { token in
            try req.verifyEmailSender.sendEmail(
                with: User.VerifyEmail.EmailContent(
                    token: token.token,
                    userID: user.id,
                    email: user.email
                )
            )
        }
    }

    public func startResetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let email = try req.content.decode(User.ResetPassword.Email.self)
        let userEmail = email.email.lowercased()

        return req.repositories { repositories in
            repositories.userRepository
                .first(with: userEmail)
                .failableFlatMap { user in
                    guard let user = user else {
                        return req.eventLoop.future(.ok)
                    }
                    return try repositories.userRepository
                        .startReset(for: user)
                        .flatMap { token in

                            req.resetPasswordSender.sendResetPassword(for: user, token: token)
                                .transform(to: .ok)
                    }
            }
        }
    }

    public func resetPassword(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        req.repositories { repositories in
            try repositories.userRepository
                .reset(
                    to: req.content.decode(User.ResetPassword.Data.self),
                    with: req.content.decode(User.ResetPassword.Token.Data.self).token
            )
            .transform(to: .ok)
        }
    }

    public func verify(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        // For Web
        if let request = try? req.query.decode(User.VerifyEmail.Token.self) {

            return req.repositories { repositories in
                try repositories.userRepository.find(req.parameters.get(User.self), or: Abort(.badRequest))
                    .flatMap { user in

                        repositories.userRepository.verify(user: user, with: request)
                            .transform(to: .ok)
                }
            }
        } else {
            // For API
            return req.repositories { repositories in
                return try repositories.userRepository.find(req.parameters.get(User.self))
                    .unwrap(or: Abort(.badRequest))
                    .failableFlatMap { user in
                        try repositories.userRepository.verify(user: user, with: req.content.decode(User.VerifyEmail.Token.self))
                }
                .transform(to: .ok)
            }
        }
    }
    
    public func feideLogin(on req: Request) -> Response {
        req.feide.loginRedirect(for: req)
    }
    
    public func handleFeideCallback(on req: Request) throws -> EventLoopFuture<Response> {
        let grant = try req.query.decode(Feide.Grant.self)
        
        return try req.feide.token(with: grant)
            .flatMap { token in
                loginFeideUser(with: token, on: req)
                    .flatMap { wasLoggedIn in
                        guard !wasLoggedIn else { return req.eventLoop.future() }
                        return createFeideUserData(with: token, on: req)
                            .flatMap { userID in
                                req.repositories { repo in
                                    repo.userRepository.saveFeide(grant: grant, for: userID)
                                }
                            }
                    }
        }
            .map {
                var response = req.redirect(to: "/subjects")
                response.cookies.isFeideLogin = true
                return response
            }
    }
        
    func loginFeideUser(with token: Feide.AccessToken, on req: Request) -> EventLoopFuture<Bool> {
        req.repositories { repo in
            repo.userRepository.user(with: token.accessToken)
                .map { tokenUser in
                    if let user = tokenUser {
                        req.auth.login(user)
                        return true
                    } else {
                        return false
                    }
                }
        }
    }
    
    func createFeideUserData(with token: Feide.AccessToken, on req: Request) -> EventLoopFuture<User.ID> {
        return req.feide.userInfo(with: token)
            .flatMap { userInfo in
                req.repositories { repo in
                    repo.userRepository.first(with: userInfo.email)
                        .failableFlatMap { emailUser in
                            if let user = emailUser {
                                return req.eventLoop.future(user)
                            } else {
                                return try repo.userRepository.unsafeCreate(userInfo, handleDuplicateSilently: true)
                            }
                    }
                    .failableFlatMap { (user) -> EventLoopFuture<User> in
                        try repo.userRepository.loginWith(feide: token, for: user.id)
                            .transform(to: user)
                    }
                }
        }
        .flatMap { user in
            req.feide.subjects(userToken: token.token)
                .flatMap { subjects in
                    req.repositories { repo in
                        repo.subjectRepository.save(subjects: subjects, for: user.id)
                    }
                }
                .transform(to: user)
        }
        .map { user in
            req.auth.login(user)
            return user.id
        }
    }
    
    private func updateActiveSubjectsBasedOnFeide(with token: Feide.AccessToken, req: Request) -> EventLoopFuture<Void> {
        req.feide.subjects(userToken: token.token)
            .map { subjects in
                subjects.filter { $0.isActive }
            }
            .transform(to: ())
    }
}

extension Feide.UserInfo: UserRepresentable {
    public var username: String { email }
    public var usedPassword: String? { nil }
}

extension Feide.AccessToken: TokenConfig {
    public var token: String { accessToken }
    public var expiresAt: Date {
        // Remove 20 sec as network and access time buffer
        Date(timeInterval: TimeInterval(expiresIn) - 20, since: Date())
    }
}

extension User {
    public typealias DefaultAPIController = UserAPIController
}
