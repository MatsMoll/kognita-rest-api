//
//  ExamSessionAPIController.swift
//  KognitaCore
//
//  Created by Mats Mollestad on 06/11/2020.
//

import Vapor
import KognitaCore

extension ExamSession: ModelParameterRepresentable {}

public enum ExamSessionAPIError: Error {
    case noTaskAtIndex(index: Int, sessionID: ExamSession.ID)
}

public protocol ExamSessionAPIController: CreateModelAPIController, RouteCollection {
    func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>>
    func submit(typingTask req: Request)         throws -> EventLoopFuture<HTTPStatus>

    func get(solutions req: Request)             throws -> EventLoopFuture<[TaskSolution.Response]>
    func getSessionResult(_ req: Request)        throws -> EventLoopFuture<Sessions.Result>
    func extend(session req: Request)            throws -> EventLoopFuture<HTTPResponseStatus>

    func estimatedScore(on req: Request)         throws -> EventLoopFuture<ClientResponse>
    func getCurrentTask(on req: Request)         throws -> EventLoopFuture<Sessions.CurrentTask>
}

extension ExamSessionAPIController {

    public func boot(routes: RoutesBuilder) throws {
        let sessionInstance = routes.grouped("exam-sessions", ExamSession.parameter)

        sessionInstance.get("tasks", Int.parameter, "solutions", use: self.get(solutions: ))
        sessionInstance.post("tasks", Int.parameter, "estimate", use: self.estimatedScore(on: ))
        sessionInstance.get("result", use: self.getSessionResult)

        sessionInstance.post("submit", "multiple-choise", use: self.submit(multipleTaskAnswer: ))
        sessionInstance.post("submit", "typing-task", use: self.submit(typingTask: ))
        sessionInstance.post("extend", use: self.extend(session: ))
    }
}
