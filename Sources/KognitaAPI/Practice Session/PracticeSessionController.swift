//
//  PracticeSessionController.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import Vapor
import KognitaCore

public struct PracticeSessionAPIController: PracticeSessionAPIControlling {

    public enum Errors: Error {
        case unableToFindTask(PracticeSessionRepresentable, User)
    }

    public func create(on req: Request) throws -> EventLoopFuture<PracticeSession> {
        try req.create(in: req.repositories.practiceSessionRepository.create(from: by: ))
    }

    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { (session) in

                try req.repositories.practiceSessionRepository
                    .submit(req.content.decode(), in: session, by: user)
        }
    }

    public func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<TypingTask.Submit>> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository
            .find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { session in

                try req.repositories.practiceSessionRepository.submit(req.content.decode(), in: session, by: user)
        }
    }

    public func end(session req: Request) throws -> EventLoopFuture<PracticeSession> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { session in
                req.repositories.practiceSessionRepository
                    .end(session, for: user)
                    .transform(to: session.content())
        }
    }

    struct HistogramQuery: Codable {
        let numberOfWeeks: Int?
        let subjectId: Subject.ID?
    }

    public func get(amountHistogram req: Request) throws -> EventLoopFuture<[TaskResult.History]> {

        let user = try req.auth.require(User.self)

        let query = try req.query.decode(HistogramQuery.self)

        if let subjectId = query.subjectId {
            return req.repositories.taskResultRepository
                .getAmountHistory(for: user, in: subjectId, numberOfWeeks: query.numberOfWeeks ?? 4)
        } else {
            return req.repositories.taskResultRepository
                .getAmountHistory(for: user, numberOfWeeks: query.numberOfWeeks ?? 4)
        }
    }

    public func get(solutions req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { session in

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }

                let index = try req.parameters.get(Int.self)

                return try req.repositories.practiceSessionRepository
                    .taskID(index: index, in: session.requireID())
                    .flatMap { taskID in

                        req.repositories.taskSolutionRepository.solutions(for: taskID, for: user)
                }
        }
    }

    /// Returns a session history
    public func get(sessions req: Request) throws -> EventLoopFuture<[PracticeSession.Overview]> {

        return try req.repositories.practiceSessionRepository
            .getAllSessionsWithSubject(by: req.auth.require(User.self))
    }

    /// Get the statistics of a session
    ///
    /// - Parameter req: The HTTP request
    /// - Returns: A rendered view
    /// - Throws: If unauth or any other error
    public func getSessionResult(_ req: Request) throws -> EventLoopFuture<PracticeSession.Result> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { session in
                guard user.id == session.userID else {
                    throw Abort(.forbidden)
                }

                return try req.repositories.practiceSessionRepository
                    .getResult(for: session.requireID())
                    .flatMap { results in

                        return req.repositories.subjectRepository
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

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository.find(req.parameters.get(PracticeSession.self))
            .failableFlatMap { session in

                let index = try req.parameters.get(Int.self)

                guard let sessionID = session.id else {
                    throw Abort(.internalServerError)
                }
                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }
                return try req.repositories.practiceSessionRepository
                    .taskAt(index: index, in: sessionID)
                    .map { taskType in

                        PracticeSession.CurrentTask(
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

    public func extend(session req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.practiceSessionRepository
            .find(req.parameters.get(PracticeSession.self))
            .and(value: user)
            .failableFlatMap(event: req.repositories.practiceSessionRepository.extend(session: for: ))
            .transform(to: .ok)
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
