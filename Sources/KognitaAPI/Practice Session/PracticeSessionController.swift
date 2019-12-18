//
//  PracticeSessionController.swift
//  App
//
//  Created by Mats Mollestad on 22/01/2019.
//

import Vapor
import FluentPostgreSQL
import KognitaCore

public final class PracticeSessionController: RouteCollection, KognitaCRUDControllable {

    public enum Errors: Error {
        case unableToFindTask(PracticeSession, User)
    }
    
    typealias Model = PracticeSession
    typealias ResponseContent = PracticeSession.Create.WebResponse

    public func boot(router: Router) {
        router.post(
            "subjects", Subject.parameter, "practice-sessions/start",
            use: PracticeSessionController.create)

        router.post(
            "practice-sessions", PracticeSession.parameter, "submit/multiple-choise",
            use: PracticeSessionController.submitMultipleTaskAnswer)

        router.post(
            "practice-sessions", PracticeSession.parameter, "submit/input",
            use: PracticeSessionController.submitInputTaskAnswer)

        router.post(
            "practice-sessions", PracticeSession.parameter, "submit/flash-card",
            use: PracticeSessionController.submitFlashCardKnowledge)

        router.get(
            "practice-session/histogram",
            use: PracticeSessionController.getAmountHistogram)

        router.post(
            "practice-session", PracticeSession.parameter,
            use: PracticeSessionController.endSession)

        router.get("practice-sessions/", PracticeSession.parameter, "tasks", Int.parameter, "solutions", use: PracticeSessionController.getSolutions)
//        router.get("practice-sessions/", PracticeSession.parameter, "result", use: getSessionResult)
        router.get("practice-sessions/history", use: PracticeSessionController.getSessions)
    }
    
    
    public static func getAll(_ req: Request) throws -> EventLoopFuture<[PracticeSession.Create.WebResponse]> {
        throw Abort(.internalServerError)
    }
    
    public static func map(model: PracticeSession, on conn: DatabaseConnectable) throws -> EventLoopFuture<PracticeSession.Create.WebResponse> {
        
        return try model
            .getCurrentTaskIndex(conn)
            .map { index in
                return try .init(
                    redirectionUrl: model.pathFor(index: index)
                )
        }
    }
    
    public static func edit(_ req: Request) throws -> EventLoopFuture<PracticeSession.Create.Response> {
        throw Abort(.internalServerError)
    }


    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public static func submitMultipleTaskAnswer(_ req: Request) throws -> Future<PracticeSessionResult<[MultipleChoiseTaskChoise.Result]>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(MultipleChoiseTask.Submit.self)
            .flatMap { submit in

                try req.parameters
                    .next(PracticeSession.self)
                    .flatMap { (session) in

                        try PracticeSession.Repository
                            .submitMultipleChoise(submit, in: session, by: user, on: req)
                }
        }
    }

    /// Submits an answer to a session
    ///
    /// - Parameter req: The http request
    /// - Returns: A response containing the result
    /// - Throws: if unautorized, database errors ext.
    public static func submitInputTaskAnswer(_ req: Request) throws -> Future<PracticeSessionResult<NumberInputTask.Submit.Response>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(NumberInputTask.Submit.Data.self)
            .flatMap { submit in

                try req.parameters
                    .next(PracticeSession.self)
                    .flatMap { session in

                        try PracticeSession.Repository
                            .submitInputTask(submit, in: session, by: user, on: req)
                }
        }
    }


    public static func submitFlashCardKnowledge(_ req: Request) throws -> Future<PracticeSessionResult<FlashCardTask.Submit>> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(FlashCardTask.Submit.self)
            .flatMap { submit in

                try req.parameters
                    .next(PracticeSession.self)
                    .flatMap { session in

                        try PracticeSession.Repository
                            .submitFlashCard(submit, in: session, by: user, on: req)
                }
        }
    }

    public static func endSession(_ req: Request) throws -> EventLoopFuture<PracticeSession> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(PracticeSession.self)
            .flatMap { session in
                try PracticeSession.Repository
                    .end(session, for: user, on: req)
//                    .transform(to:
//                        PracticeSessionEndResponse(sessionResultPath: "/practice-sessions/\(session.id ?? 0)/result")
//                )
        }
    }

    struct HistogramQuery: Codable {
        let numberOfWeeks: Int?
        let subjectId: Subject.ID?
    }

    public static func getAmountHistogram(_ req: Request) throws -> EventLoopFuture<[TaskResult.History]> {

        let user = try req.requireAuthenticated(User.self)

        let query = try req.query.decode(HistogramQuery.self)

        return req.databaseConnection(to: .psql)
            .flatMap { conn in
                if let subjectId = query.subjectId {
                    return try TaskResultRepository
                        .getAmountHistory(for: user, in: subjectId, on: conn, numberOfWeeks: query.numberOfWeeks ?? 4)
                } else {
                    return try TaskResultRepository
                        .getAmountHistory(for: user, on: conn, numberOfWeeks: query.numberOfWeeks ?? 4)
                }
        }
    }

    public static func getSolutions(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(PracticeSession.self)
            .flatMap { (session) in

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }

                let index = try req.parameters.next(Int.self)

                return try PracticeSession.Repository.taskID(index: index, in: session, on: req)
                    .flatMap { taskID in
                        TaskSolution.Repository.solutions(for: taskID, on: req)
                }
        }
    }

    /// Returns a session history
    public static func getSessions(_ req: Request) throws -> EventLoopFuture<PracticeSession.HistoryList> {

        let user = try req.requireAuthenticated(User.self)

        return req.databaseConnection(to: .psql)
            .flatMap { psqlConn in

                try PracticeSession.Repository
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

        return try req.parameters
            .next(PracticeSession.self)
            .flatMap { session in
                guard user.id == session.userID else {
                    throw Abort(.forbidden)
                }

                return try PracticeSession.Repository
                    .goalProgress(in: session, on: req)
                    .flatMap { progress in

                        try PracticeSession.Repository
                            .getResult(for: session, on: req)
                }
        }
    }


    public static func getCurrentTask(on req: Request) throws -> EventLoopFuture<PracticeSession.CurrentTask> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(PracticeSession.self)
            .flatMap { session in

                let index = try req.parameters.next(Int.self)

                guard session.userID == user.id else {
                    throw Abort(.forbidden)
                }
                return req.databaseConnection(to: .psql)
                    .flatMap { conn in

                        try session
                            .taskAt(index: index, on: conn)
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
