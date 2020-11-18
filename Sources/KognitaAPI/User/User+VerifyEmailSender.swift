import KognitaCore
import Vapor
import Mailgun

public protocol VerifyEmailRenderable {
    func render(with content: User.VerifyEmail.EmailContent, on request: Request) throws -> EventLoopFuture<String>
}

public struct VerifyEmailSenderFactory {
    var make: ((Request) -> VerifyEmailSendable)?
    public mutating func use(_ make: @escaping ((Request) -> VerifyEmailSendable)) {
        self.make = make
    }
}

public struct VerifyEmailRenderableFactory {
    var make: ((Request) -> VerifyEmailRenderable)?
    public mutating func use(_ make: @escaping ((Request) -> VerifyEmailRenderable)) {
        self.make = make
    }
}

extension Application {
    private struct VerifyEmailRenderableKey: StorageKey {
        typealias Value = VerifyEmailRenderableFactory
    }

    private struct VerifyEmailSenderKey: StorageKey {
        typealias Value = VerifyEmailSenderFactory
    }

    public var verifyEmailRenderer: VerifyEmailRenderableFactory {
        get { self.storage[VerifyEmailRenderableKey.self] ?? .init() }
        set { self.storage[VerifyEmailRenderableKey.self] = newValue }
    }

    public var verifyEmailSender: VerifyEmailSenderFactory {
        get { self.storage[VerifyEmailSenderKey.self] ?? .init() }
        set { self.storage[VerifyEmailSenderKey.self] = newValue }
    }
}
extension Request {
    public var verifyEmailRenderer: VerifyEmailRenderable {
        application.verifyEmailRenderer.make!(self)
    }
}

extension Request {
    public var verifyEmailSender: VerifyEmailSendable {
        self.application.verifyEmailSender.make!(self)
    }
}

extension User {
    struct VerifyEmailSender: VerifyEmailSendable {

        let request: Request

        func sendEmail(with token: User.VerifyEmail.EmailContent) throws -> EventLoopFuture<Void> {

            return try request.verifyEmailRenderer
                .render(with: token, on: request)
                .flatMap { html in

                    let message = MailgunMessage(
                        from: "noreply@kognita.no",
                        to: token.email,
                        subject: "Kognita - Verifiser brukeren din",
                        text: "",
                        html: html
                    )

                    return self.request
                        .mailgun()
                        .send(message)
                        .flatMapErrorThrowing { error in
                            request.logger.critical("Error when using mailgun service: \(error.localizedDescription)")
                            throw error
                        }
                        .transform(to: ())
            }
        }
    }
}
