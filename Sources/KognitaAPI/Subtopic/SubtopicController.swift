//
//  SubtopicController.swift
//  App
//
//  Created by Mats Mollestad on 26/08/2019.
//

import Vapor
import KognitaCore

public final class SubtopicController<Repository: SubtopicRepositoring>: SubtopicAPIControlling {
    
    public static func getAllIn(topic req: Request) throws -> EventLoopFuture<[Subtopic]> {
        return req.parameters
            .model(Topic.self, on: req)
            .flatMap { topic in

                try Repository
                    .getSubtopics(in: topic, with: req)
        }
    }
}

extension Subtopic {
    public typealias DefaultAPIController = SubtopicController<Subtopic.DatabaseRepository>
}
