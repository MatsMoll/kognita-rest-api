import KognitaCore
import Vapor
import Mailgun


public protocol ResetPasswordSender {
    func sendResetPassword(for user: User, token: User.ResetPassword.Token.Create.Response) -> EventLoopFuture<Void>
}

struct ResetPasswordSenderFactory {
    var make: ((Request) -> ResetPasswordSender)?
    mutating func use(_ make: @escaping ((Request) -> ResetPasswordSender)) {
        self.make = make
    }
}

extension Application {

    private struct ResetPasswordSenderKey: StorageKey {
        typealias Value = ResetPasswordSenderFactory
    }

    var resetPasswordSender: ResetPasswordSenderFactory {
        get { self.storage[ResetPasswordSenderKey.self] ?? .init() }
        set { self.storage[ResetPasswordSenderKey.self] = newValue }
    }
}

extension Request {
    var resetPasswordSender: ResetPasswordSender {
        self.application.resetPasswordSender.make!(self)
    }
}

extension User {
    struct ResetPasswordMailgunSender: ResetPasswordSender {

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
                return request.mailgun()
                    .send(mail)
                    .transform(to: ())
            } catch {
                return request.eventLoop.future(error: Abort(.internalServerError))
            }
        }
    }
}
