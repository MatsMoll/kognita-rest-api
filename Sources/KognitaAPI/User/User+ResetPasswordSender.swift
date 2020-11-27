import KognitaCore
import Vapor
import Mailgun

public protocol ResetPasswordSender {
    func sendResetPassword(for user: User, token: User.ResetPassword.Token.Create.Response) -> EventLoopFuture<Void>
}

public struct ResetPasswordSenderFactory {
    var make: ((Request) -> ResetPasswordSender)?
    mutating func use(_ make: @escaping ((Request) -> ResetPasswordSender)) {
        self.make = make
    }
}

extension Application {

    private struct ResetPasswordSenderKey: StorageKey {
        typealias Value = ResetPasswordSenderFactory
    }

    public var resetPasswordSender: ResetPasswordSenderFactory {
        get { self.storage[ResetPasswordSenderKey.self] ?? .init() }
        set { self.storage[ResetPasswordSenderKey.self] = newValue }
    }
}

extension Request {
    public var resetPasswordSender: ResetPasswordSender {
        self.application.resetPasswordSender.make!(self)
    }
}

extension User {
    struct ResetPasswordMailgunSender: ResetPasswordSender {

        static let durationLabel = "reset_password_duration"
        static let errorCounterLabel = "reset_password_errors_count"

        let request: Request

        func sendResetPassword(for user: User, token: User.ResetPassword.Token.Create.Response) -> EventLoopFuture<Void> {

            do {
                let mail = try MailgunMessage(
                    from: "kontakt@kognita.no",
                    to: user.email,
                    subject: "Kognita - Gjenopprett Passord",
                    text: "",
                    html: request.resetPasswordRenderer.render(with: token, for: user)
                )
                let start = Date()
                return request.mailgun()
                    .send(mail)
                    .always { result in
                        switch result {
                        case .success:
                            // In millisec
                            let timeUsed = Date().timeIntervalSince(start) * 1000
                            request.metrics.makeTimer(
                                label: ResetPasswordMailgunSender.durationLabel,
                                dimensions: [("toUser", "\(user.id)")]
                            )
                            .recordNanoseconds(Int64(timeUsed))
                        case .failure(let error):
                            request.logger.info("Error when using mailgun service: \(error.localizedDescription)")
                            request.metrics.makeCounter(
                                label: ResetPasswordMailgunSender.errorCounterLabel,
                                dimensions: [
                                    ("error", error.localizedDescription),
                                    ("toUser", "\(user.id)")
                                ]
                            )
                            .increment(by: 1)
                        }
                    }
                    .transform(to: ())
            } catch {
                return request.eventLoop.future(error: Abort(.internalServerError))
            }
        }
    }
}
