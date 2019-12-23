
import Vapor
import KognitaCore

public protocol TaskResultAPIControlling: RouteCollection {
    static func get(resultsOverview req: Request) throws -> EventLoopFuture<[UserResultOverview]>
}

extension TaskResultAPIControlling {

    public func boot(router: Router) throws {
        let results = router.grouped("results")
        results.get("results/overview",                  use: Self.get(resultsOverview: ))
//        router.get("results",                           use: getRevisitSchedual)
//        router.get("results/topics", Int.parameter,     use: getRevisitSchedualFilter)
//        router.get("results/export",                    use: export)
    }
}
