//
//  DefaultExamSessionAPIController.swift
//  KognitaCore
//
//  Created by Mats Mollestad on 06/11/2020.
//

import Vapor
import KognitaCore
import KognitaModels

struct DefaultExamSessionAPIController: ExamSessionAPIController {

    func submit(multipleTaskAnswer req: Request) throws -> EventLoopFuture<TaskSessionResult<[MultipleChoiceTaskChoice.Result]>> {
        req.repositories { repo in
            try repo.examSessionRepository.submit(
                req.content.decode(),
                sessionID: req.parameters.get(ExamSession.self),
                by: req.auth.require()
            )
        }
    }

    func submit(typingTask req: Request) throws -> EventLoopFuture<HTTPStatus> {
        req.repositories { repo in
            try repo.examSessionRepository.submit(
                req.content.decode(TypingTask.Submit.self),
                sessionID: req.parameters.get(ExamSession.self),
                by: req.auth.require()
            )
        }
        .transform(to: .ok)
    }

    func get(solutions req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {
        let user = try req.auth.require(User.self)

        return req.repositories { repo in
            try repo.examSessionRepository.taskID(
                index: req.parameters.get(Int.self),
                in: req.parameters.get(ExamSession.self)
            )
            .flatMap { taskID in
                repo.taskSolutionRepository.solutions(for: taskID, for: user)
            }
        }
    }

    func getSessionResult(_ req: Request) throws -> EventLoopFuture<Sessions.Result> {

        let sessionID = try req.parameters.get(ExamSession.self)

        return req.repositories { repo in

            repo.examSessionRepository
                .getResult(for: sessionID)
                .flatMap { results in

                    repo.examSessionRepository
                        .subjectFor(sessionID: sessionID)
                        .map { subject in
                            Sessions.Result(
                                subject: subject,
                                results: results
                            )
                        }
                }
        }
    }

    func extend(session req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        req.repositories { repo in
            try repo.examSessionRepository.extend(
                session: req.parameters.get(ExamSession.self),
                for: req.auth.require()
            )
        }
        .transform(to: .ok)
    }

    struct EstimateScore: Codable {
        let answer: String
    }

    func estimatedScore(on req: Request) throws -> EventLoopFuture<ClientResponse> {
        try get(solutions: req)
            .failableFlatMap { solutions in

                guard let solution = solutions.first?.solution else {
                    throw Abort(.internalServerError)
                }
                return try req.textMiningClienting.similarity(
                    between: solution,
                    and: req.content.decode(EstimateScore.self).answer
                )
        }
    }

    func getCurrentTask(on req: Request) throws -> EventLoopFuture<Sessions.CurrentTask> {

        let sessionID = try req.parameters.get(ExamSession.self)
        let index = try req.parameters.get(Int.self)
        let user = try req.auth.require(User.self)

        return req.repositories { repo in
            repo.examSessionRepository
                .taskAt(index: index, in: sessionID)
                .flatMapError { (error) in
                    req.eventLoop.future(error: ExamSessionAPIError.noTaskAtIndex(index: index, sessionID: sessionID))
                }
                .map { task in
                    Sessions.CurrentTask(
                        sessionID: sessionID,
                        task: task,
                        index: index,
                        user: user
                    )
                }
        }
    }
}
