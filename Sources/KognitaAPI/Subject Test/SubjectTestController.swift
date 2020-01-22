import Vapor
import KognitaCore

public final class SubjectTestAPIController<Repository: SubjectTestRepositoring>: SubjectTestAPIControlling {

    public init() {}

    public static func open(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(SubjectTest.self)
            .flatMap { test in
                try Repository.open(test: test, by: user, on: req)
        }
        .transform(to: .ok)
    }

    public static func enter(on req: Request) throws -> EventLoopFuture<TestSession> {
        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(SubjectTest.Enter.Request.self)
            .flatMap { request in

                try req.parameters
                    .next(SubjectTest.self)
                    .flatMap { test in

                        try Repository.enter(test: test, with: request, by: user, on: req)
                }
        }
    }

    public static func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {
        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(SubjectTest.self)
            .flatMap { test in

                try Repository.userCompletionStatus(in: test, user: user, on: req)
        }
    }

    public static func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {
        throw Abort(.notImplemented)
    }

    public static func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results> {
        throw Abort(.notImplemented)
    }

    public static func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(Subject.self)
            .flatMap { subject in

                try Repository.all(in: subject, for: user, on: req)
                    .map { tests in

                        SubjectTest.ListReponse(
                            subject: subject,
                            tests: tests
                        )
                }
        }
    }

    public static func test(withID req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse> {

        _ = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(SubjectTest.self)
            .flatMap { test in

                return try Repository.taskIDsFor(testID: test.requireID(), on: req)
                    .map { taskIDs in

                        SubjectTest.ModifyResponse(
                            test: test,
                            taskIDs: taskIDs
                        )
                }
        }
    }
}


extension SubjectTest {
    public typealias DefaultAPIController = SubjectTestAPIController<SubjectTest.DatabaseRepository>
}
