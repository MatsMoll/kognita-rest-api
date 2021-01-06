//
//  LectureNoteRecapSessionAPIController.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 05/10/2020.
//

import Vapor
import KognitaModels

public protocol LectureNoteRecapSessionAPIController: RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<LectureNote.RecapSession.ID>
    func submit(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func taskForIndex(on req: Request) throws -> EventLoopFuture<LectureNote.RecapSession.ExecuteTask>
    func solutionForIndex(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]>
    func estimateScoreForIndex(on req: Request) throws -> EventLoopFuture<ClientResponse>
    func results(on req: Request) throws -> EventLoopFuture<Sessions.Result>
}

extension LectureNote.RecapSession: ModelParameterRepresentable {}
extension LectureNote.RecapSession.Create.Data: Content {}

extension LectureNoteRecapSessionAPIController {

    func boot(routes: RoutesBuilder) throws {
        let recap = routes.grouped("lecture-note-recap")
        recap.post(use: self.create(on:))
        let recapTask = recap.grouped(LectureNote.RecapSession.parameter, "tasks", Int.parameter)
        recapTask.post("submit", use: submit(on:))
        recapTask.post("estimate", use: estimateScoreForIndex(on:))
    }
}

extension LectureNote.RecapSession {

    struct APIController: LectureNoteRecapSessionAPIController {

        func create(on req: Request) throws -> EventLoopFuture<LectureNote.RecapSession.ID> {
            req.repositories { repositories in
                try repositories.lectureNoteRecapRepository.create(recap: req.content.decode(), for: req.auth.require())
            }
        }

        func submit(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

            let index       = try req.parameters.get(Int.self)
            let sessionID   = try req.parameters.get(LectureNote.RecapSession.self)
            let user        = try req.auth.require(User.self)

            return req.repositories { repositories in
                try repositories.lectureNoteRecapRepository
                    .submit(
                        answer: req.content.decode(),
                        forIndex: index,
                        userID: user.id,
                        sessionID: sessionID
                    )
                    .transform(to: .ok)
            }
        }

        func taskForIndex(on req: Request) throws -> EventLoopFuture<LectureNote.RecapSession.ExecuteTask> {
            let index = try req.parameters.get(Int.self)
            let sessionID = try req.parameters.get(LectureNote.RecapSession.self)
            let user = try req.auth.require(User.self)

            return req.repositories { repositories in
                repositories.lectureNoteRecapRepository
                    .taskContentFor(
                        index: index,
                        sessionID: sessionID,
                        userID: user.id
                    )
            }
        }

        func solutionForIndex(on req: Request) throws -> EventLoopFuture<[TaskSolution.Response]> {
            let index = try req.parameters.get(Int.self)
            let sessionID = try req.parameters.get(LectureNote.RecapSession.self)
            let user = try req.auth.require(User.self)

            return req.repositories { repositories in
                repositories.lectureNoteRecapRepository
                    .taskIDFor(index: index, sessionID: sessionID, userID: user.id)
                    .flatMap { taskID in
                        repositories.taskSolutionRepository.solutions(for: taskID, for: user)
                    }
            }
        }

        struct EstimateScore: Codable {
            let answer: String
        }

        public func estimateScoreForIndex(on req: Request) throws -> EventLoopFuture<ClientResponse> {

            try solutionForIndex(on: req)
                .failableFlatMap { solutions in
                    guard let solution = solutions.first?.solution else {
                        throw Abort(.internalServerError)
                    }
                    return try req.textMiningClienting.similarity(between: solution, and: req.content.decode(EstimateScore.self).answer)
            }
        }

        public func results(on req: Request) throws -> EventLoopFuture<Sessions.Result> {

            let sessionID = try req.parameters.get(LectureNote.RecapSession.self)

            return req.repositories { repositories in
                repositories.lectureNoteRecapRepository
                    .subjectFor(sessionID: sessionID)
                    .flatMap { subject in

                        repositories.lectureNoteRecapRepository
                            .getResult(for: sessionID)
                            .map { results in
                                Sessions.Result(
                                    subject: subject,
                                    results: results,
                                    resources: []
                                )
                            }
                    }
            }
        }
    }
}
