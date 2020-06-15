//
//  SubtopicController.swift
//  App
//
//  Created by Mats Mollestad on 26/08/2019.
//

import Vapor
import KognitaCore

public struct SubtopicController: SubtopicAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some SubtopicRepositoring { Subtopic.DatabaseRepository(conn: conn) }

    public func create(on req: Request) throws -> EventLoopFuture<Subtopic> {
        try req.create(in: repository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subtopic.Update.Response> {
        try req.update(with: repository.updateModelWith(id: to: by: ), parameter: Subtopic.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: repository.deleteModelWith(id: by: ), parameter: Subtopic.self)
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subtopic> {
        try req.retrive(with: repository.find, parameter: Subtopic.self)
    }

    public func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]> {

        // FIXME: -- Add implementation
        throw Abort(.notImplemented)
//        return req.parameters
//            .model(Topic.self, on: req)
//            .flatMap { topic in
//
//                try Repository
//                    .getSubtopics(in: topic, with: req)
//        }
    }
}

extension Subtopic {
    public typealias DefaultAPIController = SubtopicController
}
