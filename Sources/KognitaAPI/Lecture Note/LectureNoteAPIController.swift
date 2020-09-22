//
//  LectureNoteAPIController.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 21/09/2020.
//

import Vapor
import KognitaModels

extension LectureNote: ModelParameterRepresentable {}

public protocol LectureNoteAPIController: RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<LectureNote.ID>
    func update(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension LectureNoteAPIController {
    public func boot(routes: RoutesBuilder) throws {
        routes.post("notes", use: create(on:))
        routes.put("notes", LectureNote.parameter, use: update(on: ))
    }
}

struct LectureNoteDatabaseAPIController: LectureNoteAPIController {

    func update(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.lectureNoteRepository.update(
            id: req.parameters.get(LectureNote.self),
            with: req.content.decode(),
            by: req.auth.require()
        )
        .transform(to: .ok)
    }

    func create(on req: Request) throws -> EventLoopFuture<LectureNote.ID> {
        try req.repositories.lectureNoteRepository.create(from: req.content.decode(), by: req.auth.require())
    }
}
