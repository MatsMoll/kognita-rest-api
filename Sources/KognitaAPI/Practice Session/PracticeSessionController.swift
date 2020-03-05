//
//  PracticeSessionController.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import Vapor
import FluentPostgreSQL
import KognitaCore

public final class PracticeSessionAPIController<Repository: PracticeSessionRepository>: PracticeSessionAPIControlling {

    public enum Errors: Error {
        case unableToFindTask(PracticeSessionRepresentable, User)
    }

    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public static func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiseTaskChoise.Result]>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(MultipleChoiseTask.Submit.self)
            .flatMap { submit in

                req.parameters
                    .model(TaskSession.PracticeParameter.self, on: req)
                    .flatMap { (session) in

                        try PracticeSession.DatabaseRepository
                            .submit(submit, in: session, by: user, on: req)
                }
        }
    }

    public static func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<FlashCardTask.Submit>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(FlashCardTask.Submit.self)
            .flatMap { submit in

                req.parameters
                    .model(TaskSession.PracticeParameter.self, on: req)
                    .flatMap { session in

                        try PracticeSession.DatabaseRepository
                            .submit(submit, in: session, by: user, on: req)
                }
        }
    }

    public static func end(session req: Request) throws -> EventLoopFuture<TaskSession.PracticeParameter> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSession.PracticeParameter.self, on: req)
            .flatMap { session in
                try PracticeSession.DatabaseRepository
                    .end(session, for: user, on: req)
                    .transform(to: session)
        }
    }

    struct HistogramQuery: Codable {
        let numberOfWeeks: Int?
        let subjectId: Subject.ID?
    }

    public static func get(amountHistogram req: Request) throws -> EventLoopFuture<[TaskResult.History]> {

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

    public static func get(solutions req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSession.PracticeParameter.self, on: req)
            .flatMap { (session) in

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }

                let index = try req.parameters.first(Int.self, on: req)

                return try PracticeSession.DatabaseRepository
                    .taskID(index: index, in: session.requireID(), on: req)
                    .flatMap { taskID in
                        TaskSolution.DatabaseRepository.solutions(for: taskID, for: user, on: req)
                }
        }
    }

    /// Returns a session history
    public static func get(sessions req: Request) throws -> EventLoopFuture<PracticeSession.HistoryList> {

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
    public static func getSessionResult(_ req: Request) throws -> EventLoopFuture<[PSTaskResult]> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSession.PracticeParameter.self, on: req)
            .flatMap { session in
                guard user.id == session.userID else {
                    throw Abort(.forbidden)
                }

                return try PracticeSession.DatabaseRepository
                    .getResult(for: session.requireID(), on: req)
        }
    }


    public static func getCurrentTask(on req: Request) throws -> EventLoopFuture<PracticeSession.CurrentTask> {

        let user = try req.requireAuthenticated(User.self)

        return req.parameters
            .model(TaskSession.PracticeParameter.self, on: req)
            .flatMap { session in

                let index = try req.parameters.first(Int.self, on: req)

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }
                return req.databaseConnection(to: .psql)
                    .flatMap { conn in

                        try PracticeSession.DatabaseRepository
                            .taskAt(index: index, in: session.requireID(), on: conn)
                            .map { taskType in

                                try PracticeSession.CurrentTask(
                                    session: session,
                                    task: taskType,
                                    index: index,
                                    user: user.content()
                                )
                        }
                        .catchMap { _ in
                            throw Errors.unableToFindTask(session, user)
                        }
                }
        }
    }
}

extension PracticeSession {
    public typealias DefaultAPIController = PracticeSessionAPIController<PracticeSession.DatabaseRepository>
}
