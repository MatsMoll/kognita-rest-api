import Vapor
import KognitaCore

public struct SubjectTestAPIController: SubjectTestAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<SubjectTest> {
        try req.repositories.subjectTestRepository.create(from: req.content.decode(), by: req.auth.require())
    }

    public func update(on req: Request) throws -> EventLoopFuture<SubjectTest.Update.Response> {
        try req.repositories.subjectTestRepository.updateModelWith(
            id: req.parameters.get(SubjectTest.self),
            to: req.content.decode(),
            by: req.auth.require()
        )
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.subjectTestRepository.deleteModelWith(
            id: req.parameters.get(SubjectTest.self),
            by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func open(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in
                try req.repositories.subjectTestRepository.open(test: test, by: user)
        }
        .transform(to: .ok)
    }

    public func enter(on req: Request) throws -> EventLoopFuture<TestSession> {
        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in
                try req.repositories.subjectTestRepository.enter(test: test, with: req.content.decode(), by: user)
        }
    }

    public func userCompletionStatus(on req: Request) throws -> EventLoopFuture<SubjectTest.CompletionStatus> {
        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in
                try req.repositories.subjectTestRepository.userCompletionStatus(in: test, user: user)
        }
    }

    public func taskForID(on req: Request) throws -> EventLoopFuture<SubjectTest.MultipleChoiseTaskContent> {
        throw Abort(.notImplemented)
    }

    public func results(on req: Request) throws -> EventLoopFuture<SubjectTest.Results> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in

                try req.repositories.subjectTestRepository.results(for: test, user: user)
        }
    }

    public func allInSubject(on req: Request) throws -> EventLoopFuture<SubjectTest.ListReponse> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository
            .find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap { subject in

                try req.repositories.subjectTestRepository.all(in: subject, for: user)
                    .map { tests in

                        SubjectTest.ListReponse(
                            subject: subject,
                            tests: tests
                        )
                }
        }
    }

    public func test(withID req: Request) -> EventLoopFuture<SubjectTest> {
        do {
            return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
        } catch {
            return req.eventLoop.future(error: error)
        }
    }

    public func end(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in
                try req.repositories.subjectTestRepository.end(test: test, by: user)
        }
        .transform(to: .ok)
    }

    public func scoreHistogram(req: Request) throws -> EventLoopFuture<SubjectTest.ScoreHistogram> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in

                try req.repositories.subjectTestRepository.scoreHistogram(for: test, user: user)
        }
    }

    public func modifyContent(for req: Request) throws -> EventLoopFuture<SubjectTest.ModifyResponse> {

        _ = try req.auth.require(User.self)

        return try req.repositories.subjectTestRepository.find(req.parameters.get(SubjectTest.self), or: Abort(.badRequest))
            .failableFlatMap { test in

                return try req.repositories.subjectTestRepository.taskIDsFor(testID: test.id)
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
    public typealias DefaultAPIController = SubjectTestAPIController
}
