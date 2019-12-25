import Vapor
import FluentPostgreSQL
import KognitaCore

protocol PracticeSessionAPIControlling:
    CreateModelAPIController,
    RouteCollection
    where
    CreateData == PracticeSession.Create.Data,
    CreateResponse == PracticeSession.Create.Response
{
    static func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<PracticeSessionResult<[MultipleChoiseTaskChoise.Result]>>
    static func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<PracticeSessionResult<FlashCardTask.Submit>>
    static func end(session req: Request)               throws -> EventLoopFuture<PracticeSession>
    static func get(amountHistogram req: Request)       throws -> EventLoopFuture<[TaskResult.History]>
    static func get(solutions req: Request)             throws -> EventLoopFuture<[TaskSolution.Response]>
    static func get(sessions req: Request)              throws -> EventLoopFuture<PracticeSession.HistoryList>
}

extension PracticeSessionAPIControlling {

    public func boot(router: Router) {

        let session         = router.grouped("practice-sessions")
        let sessionInstance = router.grouped("practice-sessions", PracticeSession.parameter)

        router.post("subjects", Subject.parameter, "practice-sessions/start", use: Self.create)

        session.get("history",      use: Self.get(sessions: ))
        session.get("histogram",    use: Self.get(amountHistogram: ))

        sessionInstance.get ("tasks", Int.parameter, "solutions",   use: Self.get(solutions: ))
        sessionInstance.post("/",                                   use: Self.end(session: ))
        sessionInstance.post("submit/multiple-choise",              use: Self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit/flash-card",                   use: Self.submit(flashCardKnowledge: ))
    }
}