import Vapor
import KognitaCore

extension PracticeSession: ModelParameterRepresentable {}

extension Sessions.Result: Content {}
extension PracticeSession.Overview: Content {}
extension Sessions.CurrentTask: Content {}
extension TaskSolution.Resources: Content {}

public protocol PracticeSessionAPIControlling: CreateModelAPIController, RouteCollection {
    func create(on req: Request)                 throws -> EventLoopFuture<PracticeSession.Create.Response>
    func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>>
    func submit(typingTask req: Request)         throws -> EventLoopFuture<HTTPStatus>
    func end(session req: Request)               throws -> EventLoopFuture<PracticeSession>
    func get(amountHistogram req: Request)       throws -> EventLoopFuture<[TaskResult.History]>
    func get(solutions req: Request)             throws -> EventLoopFuture<TaskSolution.Resources>
    func getSessionResult(_ req: Request)        throws -> EventLoopFuture<Sessions.Result>
    func extend(session req: Request)            throws -> EventLoopFuture<HTTPResponseStatus>
    func estimatedScore(on req: Request)         throws -> EventLoopFuture<ClientResponse>
    func getCurrentTask(on req: Request)         throws -> EventLoopFuture<Sessions.CurrentTask>
}

extension PracticeSessionAPIControlling {

    public func boot(routes: RoutesBuilder) throws {

        let session         = routes.grouped("practice-sessions")
        let sessionInstance = routes.grouped("practice-sessions", PracticeSession.parameter)

        routes.post("subjects", Subject.parameter, "practice-sessions", "start", use: self.create)

//        session.get("history", use: self.get(sessions: ))
        session.get("histogram", use: self.get(amountHistogram: ))

        sessionInstance.get("tasks", Int.parameter, "solutions", use: self.get(solutions: ))
        sessionInstance.post("tasks", Int.parameter, "estimate", use: self.estimatedScore(on: ))
        sessionInstance.get("result", use: self.getSessionResult)
        sessionInstance.post(use: self.end(session: ))
        sessionInstance.post("submit", "multiple-choise", use: self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit", "typing-task", use: self.submit(typingTask: ))
        sessionInstance.post("extend", use: self.extend(session: ))
    }
}
