import Vapor

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
