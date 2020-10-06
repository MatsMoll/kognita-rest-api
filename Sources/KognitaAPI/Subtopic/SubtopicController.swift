//
//  SubtopicController.swift
//  App
//
//  Created by Mats Mollestad on 26/08/2019.
//

import Vapor
import KognitaCore

public struct SubtopicController: SubtopicAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<Subtopic> {
        try req.repositories.subtopicRepository.create(from: req.content.decode(), by: req.auth.require())
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subtopic.Update.Response> {
        try req.repositories.subtopicRepository.updateModelWith(
            id: req.parameters.get(Subtopic.self),
            to: req.content.decode(),
            by: req.auth.require()
        )
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.subtopicRepository.deleteModelWith(
            id: req.parameters.get(Subtopic.self),
            by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subtopic> {
        try req.repositories.subtopicRepository.find(
            req.parameters.get(Subtopic.self),
            or: Abort(.badRequest)
        )
    }

    public func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]> {
        try req.repositories.subtopicRepository.subtopics(with: req.parameters.get(Topic.self))
    }
}

extension Subtopic {
    public typealias DefaultAPIController = SubtopicController
}
