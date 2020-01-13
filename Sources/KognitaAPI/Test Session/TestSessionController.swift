import Vapor
import KognitaCore


public final class TestSessionAPIController<Repository: TestSessionRepositoring>: TestSessionAPIControlling {

    public init() {}

    public static func submit(test req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(TaskSession.TestParameter.self)
            .flatMap { session in

                try Repository.submit(test: session, by: user, on: req)
        }
        .transform(to: .ok)
    }

    public static func submit(multipleChoiseTask req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(TaskSession.TestParameter.self)
            .flatMap { session in

                try req.content
                    .decode(MultipleChoiseTask.Submit.self)
                    .flatMap { content in

                        try Repository.submit(content: content, for: session, by: user, on: req)
                }
        }
        .transform(to: .ok)
    }

    public static func results(on req: Request) throws -> EventLoopFuture<TestSession.Results> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(TaskSession.TestParameter.self)
            .flatMap { session in

                try Repository.results(in: session, for: user, on: req)
        }
    }
}

