import Vapor
import KognitaModels

extension RecommendedRecap: Content {}

public struct TaskResultAPIController: TaskResultAPIControlling {

    struct RecommendedTopicQuery: Codable {
        let lowerBoundDays: Int?
        let upperBoundDays: Int?
        let limit: Int?
    }

    public func recommendedRecap(on req: Request) throws -> EventLoopFuture<[RecommendedRecap]> {

        let user = try req.auth.require(User.self)
        let query = try req.query.decode(RecommendedTopicQuery.self)
        var lowerBoundDays = -3
        var upperBoundDays = 10
        var limit = 3
        if let manualLowerBound = query.lowerBoundDays {
            lowerBoundDays = manualLowerBound.clamped(to: -50...40)
        }
        if let manualUpperBound = query.upperBoundDays {
            upperBoundDays = manualUpperBound.clamped(to: -10...40)
        }
        if let manualLimit = query.limit {
            limit = manualLimit
        }
        guard lowerBoundDays < upperBoundDays else {
            throw Abort(.badRequest, reason: "lowerBoundDays needs to be lower then upperBoundDays")
        }

        return req.repositories { repositories in
            repositories.taskResultRepository
                .recommendedRecap(for: user.id, upperBoundDays: 10, lowerBoundDays: lowerBoundDays, limit: limit)
        }
    }

    public func typingTaskResults(on req: Request) throws -> EventLoopFuture<[TypingTask.AnswerResult]> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else {
            throw Abort(.unauthorized)
        }
        let subjectID = try req.parameters.get(Subject.self)
        return req.repositories { repository in
            repository.typingTaskRepository
                .allTaskAnswers(for: subjectID)
        }
    }
}
//public struct TaskResultAPIController: TaskResultAPIControlling {

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

//    public func get(resultsOverview req: Request) throws -> EventLoopFuture<[UserResultOverview]> {
//        let user = try req.auth.require(User.self)
//        guard user.isAdmin else {
//            throw Abort(.forbidden)
//        }
//        return req.repositories.taskResultRepository.getResults()
//    }

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
//}

//extension TaskResult.Answer: Content {}
//
//extension TaskResult {
//    public typealias DefaultAPIController = TaskResultAPIController
//}
