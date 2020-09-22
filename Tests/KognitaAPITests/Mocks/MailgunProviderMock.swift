import Vapor
import Mailgun
import KognitaAPI
import KognitaCore

//class MailgunProviderMock: MailgunProvider {
//
//    var apiKey: String { "" }
//    var domain: String { "" }
//    var region: Mailgun.Region { .eu }
//
//    var toEmail: String?
//
//    func send(_ content: Mailgun.Message, on container: Container) throws -> EventLoopFuture<Response> {
//        toEmail = content.to
//        return container.future(Response(using: container))
//    }
//
//    func send(_ content: Mailgun.TemplateMessage, on container: Container) throws -> EventLoopFuture<Response> {
//        container.future(Response(using: container))
//    }
//
//    func setup(forwarding: RouteSetup, with container: Container) throws -> EventLoopFuture<Response> {
//        container.future(Response(using: container))
//    }
//
//    func createTemplate(_ template: Mailgun.Template, on container: Container) throws -> EventLoopFuture<Response> {
//        container.future(Response(using: container))
//    }
//}
//
//class ResetPasswordMailRendererMock: ResetPasswordMailRenderable {
//    func render(with token: User.ResetPassword.Token.Data, for user: User) throws -> String {
//        ""
//    }
//}
