import Vapor
import KognitaCore

public struct TestSessionAPIController: TestSessionAPIControlling {

    let repositories: RepositoriesRepresentable

    var repository: TestSessionRepositoring { repositories.testSessionRepository }

    public func submit(test req: Request) throws -> EventLoopFuture<HTTPStatus> {

//        let user = try req.requireAuthenticated(User.self)

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                try Repository.submit(test: session, by: user, on: req)
//        }
//        .transform(to: .ok)
    }

    public func submit(multipleChoiseTask req: Request) throws -> EventLoopFuture<HTTPStatus> {

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        let user = try req.requireAuthenticated(User.self)
//
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                try req.content
//                    .decode(MultipleChoiseTask.Submit.self)
//                    .flatMap { content in
//
//                        try Repository.submit(content: content, for: session, by: user, on: req)
//                }
//        }
//        .transform(to: .ok)
    }

    public func results(on req: Request) throws -> EventLoopFuture<TestSession.Results> {

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        let user = try req.requireAuthenticated(User.self)
//
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                try Repository.results(in: session, for: user, on: req)
//        }
    }

    public func overview(on req: Request) throws -> EventLoopFuture<TestSession.Overview> {

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        let user = try req.requireAuthenticated(User.self)
//
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                try Repository.overview(in: session, for: user, on: req)
//        }
    }

    public func solutions(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        let user = try req.requireAuthenticated(User.self)
//
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                let pivotID = try req.first(Int.self)
//
//                return try Repository.solutions(for: user, in: session, pivotID: pivotID, on: req)
//        }
    }

    public func detailedTaskResult(on req: Request) throws -> EventLoopFuture<TestSession.DetailedTaskResult> {

        // FIXME: -- Not imp.
        throw Abort(.notImplemented)
//        let user = try req.requireAuthenticated(User.self)
//
//        return req.parameters
//            .model(TaskSession.TestParameter.self, on: req)
//            .flatMap { session in
//
//                guard try session.userID == user.requireID() else { throw Abort(.forbidden) }
//
//                let pivotID = try req.first(Int.self)
//
//                return try Repository.results(in: session, pivotID: pivotID, on: req)
//        }
    }
}

extension TestSession {
    public typealias DefaultAPIController = TestSessionAPIController
}
