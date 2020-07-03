import Vapor
import KognitaCore

public struct TestSessionAPIController: TestSessionAPIControlling {

    public func submit(test req: Request) throws -> EventLoopFuture<HTTPStatus> {

        try req.repositories
            .testSessionRepository
            .submit(
                testID: req.parameters.get(TestSession.self),
                by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func submit(multipleChoiseTask req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.testSessionRepository
            .submit(
                content: req.content.decode(),
                sessionID: req.parameters.get(TestSession.self),
                by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func results(on req: Request) throws -> EventLoopFuture<TestSession.Results> {
        try req.repositories.testSessionRepository
            .results(
                in: req.parameters.get(TestSession.self),
                for: req.auth.require()
        )
    }

    public func overview(on req: Request) throws -> EventLoopFuture<TestSession.PreSubmitOverview> {

        let user = try req.auth.require(User.self)

        return try req.repositories.testSessionRepository
            .sessionReporesentableWith(id: req.parameters.get(TestSession.self))
            .failableFlatMap { session in
                try req.repositories.testSessionRepository.overview(in: session, for: user)
        }
    }

    public func solutions(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.auth.require(User.self)

        return try req.repositories.testSessionRepository
            .sessionReporesentableWith(id: req.parameters.get(TestSession.self))
            .failableFlatMap { session in

                guard user.id == session.userID else { return req.eventLoop.future(error: Abort(.forbidden)) }
                return try req.repositories.testSessionRepository.solutions(for: user, in: session, pivotID: req.parameters.get(Int.self))
        }
    }

    public func detailedTaskResult(on req: Request) throws -> EventLoopFuture<TestSession.DetailedTaskResult> {

        let user = try req.auth.require(User.self)

        return try req.repositories.testSessionRepository
            .sessionReporesentableWith(id: req.parameters.get(TestSession.self))
            .failableFlatMap { session in
                guard user.id == session.userID else { return req.eventLoop.future(error: Abort(.forbidden)) }
                return try req.repositories.testSessionRepository.results(in: session, pivotID: req.parameters.get(Int.self))
        }
    }
}

extension TestSession {
    public typealias DefaultAPIController = TestSessionAPIController
}
