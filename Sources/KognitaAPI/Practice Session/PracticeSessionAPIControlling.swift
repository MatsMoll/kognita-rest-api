import Vapor
import KognitaCore

extension PracticeSession: ModelParameterRepresentable {}

extension PracticeSession.Result: Content {}
extension PracticeSession.Overview: Content {}

public protocol PracticeSessionAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request)                 throws -> EventLoopFuture<PracticeSession.Create.Response>
    func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>>
    func submit(flashCardKnowledge req: Request) throws -> EventLoopFuture<TaskSessionResult<TypingTask.Submit>>
    func end(session req: Request)               throws -> EventLoopFuture<PracticeSession>
    func get(amountHistogram req: Request)       throws -> EventLoopFuture<[TaskResult.History]>
    func get(solutions req: Request)             throws -> EventLoopFuture<[TaskSolution.Response]>
    func get(sessions req: Request)              throws -> EventLoopFuture<[PracticeSession.Overview]>
    func getSessionResult(_ req: Request)        throws -> EventLoopFuture<PracticeSession.Result>
    func extend(session req: Request)            throws -> EventLoopFuture<HTTPResponseStatus>
    func estimatedScore(on req: Request)         throws -> EventLoopFuture<ClientResponse>
    func getCurrentTask(on req: Request)         throws -> EventLoopFuture<PracticeSession.CurrentTask>
}

extension PracticeSessionAPIControlling {

    public func boot(routes: RoutesBuilder) throws {

        let session         = routes.grouped("practice-sessions")
        let sessionInstance = routes.grouped("practice-sessions", PracticeSession.parameter)

        routes.post("subjects", Subject.parameter, "practice-sessions", "start", use: self.create)

        session.get("history", use: self.get(sessions: ))
        session.get("histogram", use: self.get(amountHistogram: ))

        sessionInstance.get("tasks", Int.parameter, "solutions", use: self.get(solutions: ))
        sessionInstance.post("tasks", Int.parameter, "estimate", use: self.estimatedScore(on: ))
        sessionInstance.get("result", use: self.getSessionResult)
        sessionInstance.post(use: self.end(session: ))
        sessionInstance.post("submit", "multiple-choise", use: self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit", "flash-card", use: self.submit(flashCardKnowledge: ))
        sessionInstance.post("extend", use: self.extend(session: ))
    }
}
