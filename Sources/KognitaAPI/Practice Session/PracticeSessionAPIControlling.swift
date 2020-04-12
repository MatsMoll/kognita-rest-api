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
    static func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiseTaskChoise.Result]>>
    static func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<FlashCardTask.Submit>>
    static func end(session req: Request)               throws -> EventLoopFuture<TaskSession.PracticeParameter>
    static func get(amountHistogram req: Request)       throws -> EventLoopFuture<[TaskResult.History]>
    static func get(solutions req: Request)             throws -> EventLoopFuture<[TaskSolution.Response]>
    static func get(sessions req: Request)              throws -> EventLoopFuture<PracticeSession.HistoryList>
    static func getSessionResult(_ req: Request)        throws -> EventLoopFuture<PracticeSession.Result>
    static func extend(session req: Request)            throws -> EventLoopFuture<HTTPResponseStatus>
    static func estimatedScore(on req: Request)         throws -> EventLoopFuture<Response>
}

extension PracticeSessionAPIControlling {

    public func boot(router: Router) {

        let session         = router.grouped("practice-sessions")
        let sessionInstance = router.grouped("practice-sessions", TaskSession.PracticeParameter.parameter)

        router.post("subjects", Subject.parameter, "practice-sessions/start", use: Self.create)

        session.get("history",      use: Self.get(sessions: ))
        session.get("histogram",    use: Self.get(amountHistogram: ))

        sessionInstance.get ("tasks", Int.parameter, "solutions",   use: Self.get(solutions: ))
        sessionInstance.post("tasks", Int.parameter, "estimate",    use: Self.estimatedScore(on: ))
        sessionInstance.get ("result",                              use: Self.getSessionResult)
        sessionInstance.post("/",                                   use: Self.end(session: ))
        sessionInstance.post("submit/multiple-choise",              use: Self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit/flash-card",                   use: Self.submit(flashCardKnowledge: ))
        sessionInstance.post("extend",                              use: Self.extend(session: ))
    }
}
