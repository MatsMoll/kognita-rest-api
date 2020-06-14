//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore
import FluentPostgreSQL

public struct TaskDiscussionAPIController: TaskDiscussionAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some TaskDiscussionRepositoring { TaskDiscussion.DatabaseRepository(conn: conn) }

    public func create(on req: Request) throws -> EventLoopFuture<NoData> {
        try createImplementation(
            TaskDiscussion.Create.Data.self,
            from: req,
            repository: repository.create(from: by: )
        )
    }

    public func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        try repository.getDiscussions(in: req.parameters.modelID(TaskDiscussion.self))
    }

    public func getDiscussionsForUser(on req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        try repository.getUserDiscussions(for: req.requireAuthenticated())
    }
}

extension TaskDiscussion {
    public typealias DefaultAPIController = TaskDiscussionAPIController
}
