//
//  TopicController.swift
//  App
//
//  Created by Mats Mollestad on 07/10/2018.
//

import FluentPostgreSQL
import Vapor
import KognitaCore

public final class TopicAPIController<Repository: TopicRepository>: TopicAPIControlling {
    
    public static func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]> {
        return req.parameters
            .model(Subject.self, on: req)
            .flatMap { (subject) in

                try Repository
                    .getTopics(in: subject, conn: req)
        }
    }
}

extension Topic {
    public typealias DefaultAPIController = TopicAPIController<Topic.DatabaseRepository>
}
