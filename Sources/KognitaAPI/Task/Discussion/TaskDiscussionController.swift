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

    let repositories: RepositoriesRepresentable

    public var repository: TaskDiscussionRepositoring { repositories.taskDiscussionRepository }

    public func create(on req: Request) throws -> EventLoopFuture<NoData> {
        try req.create(in: repository.create(from: by: )) 
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Update.Response> {
        try req.update(with: repository.updateModelWith(id: to: by: ), parameter: TaskDiscussion.self)
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
