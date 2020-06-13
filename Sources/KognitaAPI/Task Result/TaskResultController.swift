import Vapor
import FluentPostgreSQL
import KognitaCore

public struct TaskResultAPIController: TaskResultAPIControlling {

    let conn: DatabaseConnectable

    var repository: TaskResultRepositoring.Type { TaskResult.DatabaseRepository.self }

//    static func getRevisitSchedual(_ req: Request) throws -> EventLoopFuture<[TaskResult]> {
//
//        let user = try req.requireAuthenticated(User.self)
//
//        return try Repository
//            .getAllResults(for: user.requireID(), with: req)
//    }

//    static func getRevisitSchedualFilter(_ req: Request) throws -> EventLoopFuture<[TaskResult]> {
//
//        let user = try req.requireAuthenticated(User.self)
//        let topicID = try req.parameters.next(Int.self)
//
//        return req.databaseConnection(to: .psql)
//            .flatMap { conn in
//                try TaskResultRepository
//                    .getAllResults(for: user.requireID(), filter: \Topic.id == topicID, with: conn)
//        }
//    }

    public func get(resultsOverview req: Request) throws -> EventLoopFuture<[UserResultOverview]> {
        let user = try req.requireAuthenticated(User.self)
        guard user.isAdmin else {
            throw Abort(.forbidden)
        }
        return repository
            .getResults(on: conn)
    }

//    static func export(on req: Request) throws -> EventLoopFuture<[TaskResult.Answer]> {
//
//        let user = try req.requireAuthenticated(User.self)
//
//        guard user.role == .admin else {
//            throw Abort(.forbidden)
//        }
//
//        return try TaskResultRepository
//            .exportResults(on: req)
//    }
}

extension TaskResult.Answer: Content {}

extension TaskResult {
    public typealias DefaultAPIController = TaskResultAPIController
}
