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
