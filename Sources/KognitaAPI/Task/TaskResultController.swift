//
//  TaskResultController.swift
//  App
//
//  Created by Mats Mollestad on 01/04/2019.
//

import Vapor
import FluentPostgreSQL
import KognitaCore


class TaskResultController: RouteCollection {

    func boot(router: Router) throws {
        router.get("results",                           use: getRevisitSchedual)
        router.get("results/topics", Int.parameter,     use: getRevisitSchedualFilter)
        router.get("results/overview",                  use: getResultsOverview)
        router.get("results/export",                    use: export)
    }

    func getRevisitSchedual(_ req: Request) throws -> EventLoopFuture<[TaskResult]> {

        let user = try req.requireAuthenticated(User.self)

        return req.databaseConnection(to: .psql)
            .flatMap { conn in
                try TaskResultRepository
                    .getAllResults(for: user.requireID(), with: conn)
        }
    }

    func getRevisitSchedualFilter(_ req: Request) throws -> EventLoopFuture<[TaskResult]> {

        let user = try req.requireAuthenticated(User.self)
        let topicID = try req.parameters.next(Int.self)

        return req.databaseConnection(to: .psql)
            .flatMap { conn in
                try TaskResultRepository
                    .getAllResults(for: user.requireID(), filter: \Topic.id == topicID, with: conn)
        }
    }

    func getResultsOverview(on req: Request) throws -> EventLoopFuture<[UserResultOverview]> {
        let user = try req.requireAuthenticated(User.self)
        guard user.isCreator else {
            throw Abort(.forbidden)
        }
        return req.databaseConnection(to: .psql)
            .flatMap { conn in
                TaskResultRepository.getResults(on: conn)
        }
    }

    func export(on req: Request) throws -> EventLoopFuture<[TaskResult.Answer]> {

        let user = try req.requireAuthenticated(User.self)

        guard user.role == .admin else {
            throw Abort(.forbidden)
        }

        return try TaskResultRepository
            .exportResults(on: req)
    }
}

extension TaskResult.Answer: Content {}
