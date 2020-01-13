import Vapor
import KognitaCore

public final class SubjectTestAPIController<Repository: SubjectTestRepositoring>: SubjectTestAPIControlling {

    public init() {}

    static func open(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(SubjectTest.self)
            .flatMap { test in
                try Repository.open(test: test, by: user, on: req)
        }
        .transform(to: .ok)
    }

    static func enter(on req: Request) throws -> EventLoopFuture<TestSession> {
        throw Abort(.notImplemented)
    }

    static func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {
        throw Abort(.notImplemented)
    }

    static func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {
        throw Abort(.notImplemented)
    }

    static func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results> {
        throw Abort(.notImplemented)
    }
}


extension SubjectTest {
    public typealias DefaultAPIController = SubjectTestAPIController<SubjectTest.DatabaseRepository>
}
