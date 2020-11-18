//
//  PracticeSessionController.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import Vapor
import KognitaModels
import KognitaCore

public struct PracticeSessionAPIController: PracticeSessionAPIControlling {

    public enum Errors: Error {
        case unableToFindTask(PracticeSessionRepresentable, User)
    }

    public func create(on req: Request) throws -> EventLoopFuture<PracticeSession> {
        req.repositories { repositories in
            try repositories.practiceSessionRepository.create(
                from: req.content.decode(PracticeSession.Create.Data.self),
                by: req.auth.require()
            )
        }
    }

    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { (session) in

                    try repositories.practiceSessionRepository
                        .submit(req.content.decode(), in: session, by: user)
            }
        }
    }

    public func submit(typingTask req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.practiceSessionRepository
                .find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in

                    try repositories.practiceSessionRepository.submit(
                        req.content.decode(TypingTask.Submit.self),
                        in: session,
                        by: user
                    )
                    .transform(to: .ok)
            }
        }
    }

    public func end(session req: Request) throws -> EventLoopFuture<PracticeSession> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in
                    repositories.practiceSessionRepository
                        .end(session, for: user)
                        .transform(to: session.content())
            }
        }
    }

    struct HistogramQuery: Codable {
        let numberOfWeeks: Int?
        let subjectId: Subject.ID?
    }

    public func get(amountHistogram req: Request) throws -> EventLoopFuture<[TaskResult.History]> {

        let user = try req.auth.require(User.self)

        let query = try req.query.decode(HistogramQuery.self)

        return req.repositories { repositories in
            if let subjectId = query.subjectId {
                return repositories.taskResultRepository
                    .getAmountHistory(for: user, in: subjectId, numberOfWeeks: query.numberOfWeeks ?? 4)
            } else {
                return repositories.taskResultRepository
                    .getAmountHistory(for: user, numberOfWeeks: query.numberOfWeeks ?? 4)
            }
        }
    }

    public func get(solutions req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in

                    guard session.userID == user.id else {
                        throw Abort(.forbidden)
                    }

                    let index = try req.parameters.get(Int.self)

                    return try repositories.practiceSessionRepository
                        .taskID(index: index, in: session.requireID())
                        .flatMap { taskID in

                            repositories.taskSolutionRepository.solutions(for: taskID, for: user)
                    }
            }
        }
    }

    /// Get the statistics of a session
    ///
    /// - Parameter req: The HTTP request
    /// - Returns: A rendered view
    /// - Throws: If unauth or any other error
    public func getSessionResult(_ req: Request) throws -> EventLoopFuture<Sessions.Result> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.practiceSessionRepository
                .find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in
                    guard user.id == session.userID else {
                        throw Abort(.forbidden)
                    }

                    return try repositories.practiceSessionRepository
                        .getResult(for: session.requireID())
                        .flatMap { results in

                            return repositories.subjectRepository
                                .subject(for: session)
                                .map { subject in

                                    Sessions.Result(
                                        subject: subject,
                                        results: results
                                    )
                            }
                    }
            }
        }
    }

    public func getCurrentTask(on req: Request) throws -> EventLoopFuture<Sessions.CurrentTask> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in

                    let index = try req.parameters.get(Int.self)

                    guard let sessionID = session.id else {
                        throw Abort(.internalServerError)
                    }
                    guard session.userID == user.id else {
                        throw Abort(.forbidden)
                    }
                    return try repositories.practiceSessionRepository
                        .taskAt(index: index, in: sessionID)
                        .map { taskType in

                            Sessions.CurrentTask(
                                sessionID: sessionID,
                                task: taskType,
                                index: index,
                                user: user
                            )
                    }
                    .flatMapErrorThrowing { _ in
                        throw Errors.unableToFindTask(session, user)
                    }
            }
        }
    }

    public func extend(session req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.practiceSessionRepository
                .find(req.parameters.get(PracticeSession.self))
                .failableFlatMap { session in
                    try repositories.practiceSessionRepository.extend(session: session.requireID(), for: user)
                }
                .transform(to: .ok)
        }
    }

    struct EstimateScore: Codable {
        let answer: String
    }

    public func estimatedScore(on req: Request) throws -> EventLoopFuture<ClientResponse> {

        return try self.get(solutions: req)
            .failableFlatMap { solutions in

                guard let solution = solutions.first?.solution else {
                    throw Abort(.internalServerError)
                }

                return try req.textMiningClienting.similarity(between: solution, and: req.content.decode(EstimateScore.self).answer)
        }
    }

}

extension PracticeSession {
    public typealias DefaultAPIController = PracticeSessionAPIController
}
