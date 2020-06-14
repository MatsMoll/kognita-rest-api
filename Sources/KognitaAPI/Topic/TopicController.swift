//
//  TopicController.swift
//  App
//
//  Created by Mats Mollestad on 07/10/2018.
//

import FluentPostgreSQL
import Vapor
import KognitaCore

public struct TopicAPIController: TopicAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some TopicRepository { Topic.DatabaseRepository(conn: conn) }

    public func create(on req: Request) throws -> EventLoopFuture<Topic> {
        try req.create(in: repository.create(from:  by: ))
    }

    public func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]> {
        // FIXME: -- Add imp.
        throw Abort(.notImplemented)
    }
}

extension Topic {
    public typealias DefaultAPIController = TopicAPIController
}
