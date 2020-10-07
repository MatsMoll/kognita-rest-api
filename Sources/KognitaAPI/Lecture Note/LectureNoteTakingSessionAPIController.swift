//
//  LectureNoteTakingSessionAPIController.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 28/09/2020.
//

import Vapor
import KognitaModels

extension LectureNote.TakingSession: Content {}

public protocol LectureNoteTakingSessionAPIController: RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<LectureNote.TakingSession>
}

extension LectureNoteTakingSessionAPIController {
    func boot(routes: RoutesBuilder) throws {
        routes.post("note-taking-sessions", use: self.create(on: ))
    }
}

extension LectureNote.TakingSession {
    struct APIController: LectureNoteTakingSessionAPIController {
        func create(on req: Request) throws -> EventLoopFuture<LectureNote.TakingSession> {
            try req.repositories.lectureNoteTakingRepository.create(for: req.auth.require())
        }
    }
}
