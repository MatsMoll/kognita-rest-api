import Vapor
import FluentPostgreSQL
import KognitaCore

extension PracticeSession: ModelParameterRepresentable {}

extension PracticeSession.Result: Content {}

protocol PracticeSessionAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request)                 throws -> EventLoopFuture<PracticeSession.Create.Response>
    func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiseTaskChoise.Result]>>
    func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<FlashCardTask.Submit>>
    func end(session req: Request)               throws -> EventLoopFuture<PracticeSession>
    func get(amountHistogram req: Request)       throws -> EventLoopFuture<[TaskResult.History]>
    func get(solutions req: Request)             throws -> EventLoopFuture<[TaskSolution.Response]>
    func get(sessions req: Request)              throws -> EventLoopFuture<PracticeSession.HistoryList>
    func getSessionResult(_ req: Request)        throws -> EventLoopFuture<PracticeSession.Result>
    func extend(session req: Request)            throws -> EventLoopFuture<HTTPResponseStatus>
    func estimatedScore(on req: Request)         throws -> EventLoopFuture<Response>
}

extension PracticeSessionAPIControlling {

    public func boot(router: Router) {

        let session         = router.grouped("practice-sessions")
        let sessionInstance = router.grouped("practice-sessions", TestSession.parameter)

        router.post("subjects", Subject.parameter, "practice-sessions/start", use: self.create)

        session.get("history", use: self.get(sessions: ))
        session.get("histogram", use: self.get(amountHistogram: ))

        sessionInstance.get("tasks", Int.parameter, "solutions", use: self.get(solutions: ))
        sessionInstance.post("tasks", Int.parameter, "estimate", use: self.estimatedScore(on: ))
        sessionInstance.get("result", use: self.getSessionResult)
        sessionInstance.post("/", use: self.end(session: ))
        sessionInstance.post("submit/multiple-choise", use: self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit/flash-card", use: self.submit(flashCardKnowledge: ))
        sessionInstance.post("extend", use: self.extend(session: ))
    }
}
