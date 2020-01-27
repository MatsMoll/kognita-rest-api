import KognitaCore
import Vapor
import Mailgun

public protocol VerifyEmailRenderable {
    func render(with content: User.VerifyEmail.EmailContent, on container: Container) throws -> EventLoopFuture<String>
}

extension User {
    final class VerifyEmailSender: VerifyEmailSendable, Service {

        func sendEmail(with token: User.VerifyEmail.EmailContent, on container: Container) throws -> EventLoopFuture<Void> {

            let renderer = try container.make(VerifyEmailRenderable.self)
            let mailgun = try container.make(Mailgun.self)

            return try renderer.render(with: token, on: container)
                .flatMap { html in

                    let message = Mailgun.Message(
                        from: "noreply@kognita.no",
                        to: token.email,
                        subject: "Kognita - Verifiser brukeren din",
                        text: "",
                        html: html
                    )

                    return try mailgun.send(message, on: container)
                        .transform(to: ())
            }
        }
    }
}
