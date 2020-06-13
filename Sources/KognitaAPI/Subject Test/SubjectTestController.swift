import Vapor
import KognitaCore

public struct SubjectTestAPIController: SubjectTestAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some SubjectTestRepositoring { SubjectTest.DatabaseRepository(conn: conn) }
    public var subjectRepository: some SubjectRepositoring { Subject.DatabaseRepository(conn: conn) }

    public func open(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)


        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in
                try self.repository.open(test: test, by: user)
        }
        .transform(to: .ok)
    }

    public func enter(on req: Request) throws -> EventLoopFuture<TestSession> {
        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(SubjectTest.Enter.Request.self)
            .flatMap { request in

                try self.repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
                    .flatMap { test in

                        try self.repository.enter(test: test, with: request, by: user)
                }
        }
    }

    public func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {
        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in

                try self.repository.userCompletionStatus(in: test, user: user)
        }
    }

    public func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {
        throw Abort(.notImplemented)
    }

    public func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in

                try self.repository.results(for: test, user: user)
        }
    }

    public func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse> {

        let user = try req.requireAuthenticated(User.self)

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap { subject in

                try self.repository.all(in: subject, for: user)
                    .map { tests in

                        SubjectTest.ListReponse(
                            subject: subject,
                            tests: tests
                        )
                }
        }
    }

    public func test(withID req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse> {

        _ = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in

                return try self.repository.taskIDsFor(testID: test.id)
                    .map { taskIDs in

                        SubjectTest.ModifyResponse(
                            test: test,
                            taskIDs: taskIDs
                        )
                }
        }
    }

    public func end(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in
                try self.repository.end(test: test, by: user)
        }
        .transform(to: .ok)
    }

    public func scoreHistogram(req: Request) throws -> EventLoopFuture<SubjectTest.ScoreHistogram> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(SubjectTest.self), or: Abort(.badRequest))
            .flatMap { test in

                try self.repository.scoreHistogram(for: test, user: user)
        }
    }
}

extension SubjectTest {
    public typealias DefaultAPIController = SubjectTestAPIController
}
