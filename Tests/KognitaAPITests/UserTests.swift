import XCTest
import Vapor
@testable import KognitaCore
@testable import KognitaAPI
import KognitaCoreTestable
import Mailgun

extension User.Create.Data: Content {}

class UserTests: VaporTestCase {
    
    private let uri = "/api/users"
    
    
    func testLoginSuccess() throws {

        let user = try User.create(email: "test@1.com", on: app)

        var headers = standardHeaders
        headers.add(name: .authorization, value: "Basic dGVzdEAxLmNvbTpwYXNzd29yZA==")

        try app.sendRequest(to: uri + "/login", method: .POST, headers: headers) { response in
            response.has(statusCode: .ok)

            let token = try response.content.decode(User.Login.Token.self)
            XCTAssert(token.userID == user.id, "The user id is not equal to the logged in user")
        }
    }
    
    func testLoginFail() throws {

        _ = try User.create(on: app)

        var headers = standardHeaders
        headers.add(name: .authorization, value: "Basic dGVzdEAxLmNvbTpwYXNzd29y")

        try app.sendRequest(to: uri + "/login", method: .POST, headers: headers) {
            $0.has(statusCode: .unauthorized)
        }
    }
    
    
    func testCreateUserSuccess() throws {

        _ = try User.create(on: app)

//        let jobQueue = try app.make(JobQueueable.self) as! JobQueueMock

        let newUser = User.Create.Data(
            username: "Mats",
            email: "test@ntnu.no",
            password: "password",
            verifyPassword: "password",
            pictureUrl: nil,
            acceptedTerms: .accepted
        )
        try app.sendRequest(to: uri, method: .POST, headers: standardHeaders, body: newUser) { response in

    //        wait(for: [jobQueue.expectation], timeout: .seconds(1))
            response.has(statusCode: .ok)

            let user = try response.content.decode(User.Create.Response.self)

    //        XCTAssertEqual(jobQueue.jobDelay, TimeAmount.seconds(30))
            XCTAssert(user.username == newUser.username, "The name is different: \(user.username)")
            XCTAssert(user.email == newUser.email, "The email is different: \(user.email)")
        }
    }
    
    func testCreateUserExistingEmail() throws {

        let user = try User.create(on: app)
        let newUser = User.Create.Data(
            username: "Mats",
            email: user.email,
            password: "password",
            verifyPassword: "password",
            pictureUrl: nil,
            acceptedTerms: .accepted
        )
        try app.sendRequest(to: uri, method: .POST, headers: standardHeaders, body: newUser) { response in
            response.has(statusCode: .internalServerError)
        }
    }
    
    func testCreateUserPasswordMismatch() throws {
        let newUser = User.Create.Data(
            username: "Mats",
            email: "test@3.com",
            password: "password1",
            verifyPassword: "not matching",
            pictureUrl: nil,
            acceptedTerms: .accepted
        )

        try app.sendRequest(to: uri, method: .POST, headers: standardHeaders, body: newUser) { response in
            response.has(statusCode: .internalServerError)
        }
    }

    func testSendResetPasswordMail() throws {
        _ = try User.create(username: "Mron", email: "test@test.no", isAdmin: false, isEmailVerified: false, on: app)

        let uppercasedEmail = "TEst@test.no"
        let resetUri = uri + "/send-reset-mail"
        let body = User.ResetPassword.Email(email: uppercasedEmail)
        try app.sendRequest(to: resetUri, method: .POST, body: body) { response in
            response.has(statusCode: .ok)
            
                    // FIXME: -- Dep. inject
            //        let mailMock = try app.make(MailgunProvider.self) as! MailgunProviderMock
            //        XCTAssertEqual(mailMock.toEmail, uppercasedEmail.lowercased())

        }
    }
    
    static let allTests = [
        ("testLoginSuccess", testLoginSuccess),
        ("testLoginFail", testLoginFail),
        ("testCreateUserSuccess", testCreateUserSuccess),
        ("testCreateUserExistingEmail", testCreateUserExistingEmail),
        ("testCreateUserPasswordMismatch", testCreateUserPasswordMismatch),
        ("testSendResetPasswordMail", testSendResetPasswordMail)
    ]
}
