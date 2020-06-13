//
//  PracticeSessionController.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import Vapor
import FluentPostgreSQL
import KognitaCore

public struct PracticeSessionAPIController: PracticeSessionAPIControlling {

    public enum Errors: Error {
        case unableToFindTask(PracticeSessionRepresentable, User)
    }

    let conn: DatabaseConnectable

    public var repository: some PracticeSessionRepository { PracticeSession.DatabaseRepository(conn: conn) }
    var solutionRepository: some TaskSolutionRepositoring { TaskSolution.DatabaseRepository(conn: conn) }
    var subjectRepository: some SubjectRepositoring { Subject.DatabaseRepository(conn: conn) }

    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiseTaskChoise.Result]>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(MultipleChoiceTask.Submit.self)
            .flatMap { submit in

                try self.repository.find(req.parameters.modelID(PracticeSession.self))
                    .flatMap { (session) in

                        try self.repository
                            .submit(submit, in: session, by: user)
                }
        }
    }

    public func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<FlashCardTask.Submit>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(FlashCardTask.Submit.self)
            .flatMap { submit in

                try self.repository
                    .find(req.parameters.modelID(PracticeSession.self))
                    .flatMap { session in

                        try self.repository.submit(submit, in: session, by: user)
                }
        }
    }

    public func end(session req: Request) throws -> EventLoopFuture<PracticeSession> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(PracticeSession.self))
            .flatMap { session in
                try self.repository
                    .end(session, for: user)
                    .transform(to: session.content())
        }
    }

    struct HistogramQuery: Codable {
        let numberOfWeeks: Int?
        let subjectId: Subject.ID?
    }

    public func get(amountHistogram req: Request) throws -> EventLoopFuture<[TaskResult.History]> {

        let user = try req.requireAuthenticated(User.self)

        let query = try req.query.decode(HistogramQuery.self)

        return req.databaseConnection(to: .psql)
            .flatMap { conn in
                if let subjectId = query.subjectId {
                    return try TaskResult.DatabaseRepository
                        .getAmountHistory(for: user, in: subjectId, on: conn, numberOfWeeks: query.numberOfWeeks ?? 4)
                } else {
                    return try TaskResult.DatabaseRepository
                        .getAmountHistory(for: user, on: conn, numberOfWeeks: query.numberOfWeeks ?? 4)
                }
        }
    }

    public func get(solutions req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(PracticeSession.self))
            .flatMap { session in

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }

                let index = try req.first(Int.self)

                return try self.repository
                    .taskID(index: index, in: session.requireID())
                    .flatMap { taskID in

                        self.solutionRepository.solutions(for: taskID, for: user)
                }
        }
    }

    /// Returns a session history
    public func get(sessions req: Request) throws -> EventLoopFuture<PracticeSession.HistoryList> {

        let user = try req.requireAuthenticated(User.self)

        return req.databaseConnection(to: .psql)
            .flatMap { psqlConn in

                try PracticeSession.DatabaseRepository
                    .getAllSessionsWithSubject(by: user, on: psqlConn)
        }
    }

    /// Get the statistics of a session
    ///
    /// - Parameter req: The HTTP request
    /// - Returns: A rendered view
    /// - Throws: If unauth or any other error
    public func getSessionResult(_ req: Request) throws -> EventLoopFuture<PracticeSession.Result> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(PracticeSession.self))
            .flatMap { session in
                guard user.id == session.userID else {
                    throw Abort(.forbidden)
                }

                return try self.repository
                    .getResult(for: session.requireID())
                    .flatMap { results in

                        return self.subjectRepository
                            .subject(for: session)
                            .map { subject in

                                PracticeSession.Result(
                                    subject: subject,
                                    results: results
                                )
                        }
                }
        }
    }

    public func getCurrentTask(on req: Request) throws -> EventLoopFuture<PracticeSession.CurrentTask> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.find(req.parameters.modelID(PracticeSession.self))
            .flatMap { session in

                let index = try req.first(Int.self)

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }
                return req.databaseConnection(to: .psql)
                    .flatMap { conn in

                        try self.repository
                            .taskAt(index: index, in: session.requireID())
                            .map { taskType in

                                PracticeSession.CurrentTask(
                                    session: session.content(),
                                    task: taskType,
                                    index: index,
                                    user: user
                                )
                        }
                        .catchMap { _ in
                            throw Errors.unableToFindTask(session, user)
                        }
                }
        }
    }

    func extend(session req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try repository
            .find(req.parameters.modelID(PracticeSession.self))
            .and(result: user)
            .flatMap(repository.extend(session: for: ))
            .transform(to: .ok)
    }

    struct EstimateScore: Codable {
        let answer: String
    }

    func estimatedScore(on req: Request) throws -> EventLoopFuture<Response> {

        return try req.content
            .decode(EstimateScore.self)
            .flatMap { submit in

                try self.get(solutions: req)
                    .flatMap { solutions in

                        let textClient = try req.make(TextMiningClienting.self)

                        guard let solution = solutions.first?.solution else {
                            throw Abort(.internalServerError)
                        }

                        return try textClient.similarity(between: solution, and: submit.answer, on: req)
                }
        }
    }

}

extension PracticeSession {
    public typealias DefaultAPIController = PracticeSessionAPIController
}
