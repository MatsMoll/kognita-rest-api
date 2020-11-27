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

        static let durationLabel = "verify_email_duration"
        static let errorCounterLabel = "verify_email_errors_count"

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

                    let start = Date()
                    return self.request
                        .mailgun()
                        .send(message)
                        .always { result in
                            switch result {
                            case .success:
                                // In millisec
                                let timeUsed = Date().timeIntervalSince(start) * 1000
                                request.metrics.makeTimer(
                                    label: VerifyEmailSender.durationLabel,
                                    dimensions: [("toUser", "\(token.userID)")]
                                )
                                .recordNanoseconds(Int64(timeUsed))
                            case .failure(let error):
                                request.logger.info("Error when using mailgun service: \(error.localizedDescription)")
                                request.metrics.makeCounter(
                                    label: VerifyEmailSender.errorCounterLabel,
                                    dimensions: [
                                        ("error", error.localizedDescription),
                                        ("toUser", "\(token.userID)")
                                    ]
                                )
                                .increment(by: 1)
                            }
                        }
                        .transform(to: ())
            }
        }
    }
}
