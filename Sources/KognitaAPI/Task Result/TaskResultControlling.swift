import Vapor
import KognitaModels

extension TypingTask.AnswerResult: Content {}

public protocol TaskResultAPIControlling: RouteCollection {
    func recommendedRecap(on req: Request) throws -> EventLoopFuture<[RecommendedRecap]>
    func typingTaskResults(on req: Request) throws -> EventLoopFuture<[TypingTask.AnswerResult]>
}

extension TaskResultAPIControlling {
    public func boot(routes: RoutesBuilder) throws {
        routes.get("recommended-recap", use: recommendedRecap)
        routes.on(.GET, "subjects", Subject.parameter, "typing-task-results", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: typingTaskResults)
    }
}

//public protocol TaskResultAPIControlling: RouteCollection {
//    func get(resultsOverview req: Request) throws -> EventLoopFuture<[UserResultOverview]>
//}
//
//extension TaskResultAPIControlling {
//
//    public func boot(routes: RoutesBuilder) throws {
//        let results = routes.grouped("results")
//        results.get("overview", use: self.get(resultsOverview: ))
//        router.get("results",                           use: getRevisitSchedual)
//        router.get("results/topics", Int.parameter,     use: getRevisitSchedualFilter)
//        router.get("results/export",                    use: export)
//    }
//}
