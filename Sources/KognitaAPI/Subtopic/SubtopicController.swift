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
        try req.create(in: req.repositories.subtopicRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subtopic.Update.Response> {
        try req.update(with: req.repositories.subtopicRepository.updateModelWith(id: to: by: ), parameter: Subtopic.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.subtopicRepository.deleteModelWith(id: by: ), parameter: Subtopic.self)
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subtopic> {
        try req.retrive(with: req.repositories.subtopicRepository.find, parameter: Subtopic.self)
    }

    public func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]> {
        try req.repositories.subtopicRepository.subtopics(with: req.parameters.get(Topic.self))
    }
}

extension Subtopic {
    public typealias DefaultAPIController = SubtopicController
}
