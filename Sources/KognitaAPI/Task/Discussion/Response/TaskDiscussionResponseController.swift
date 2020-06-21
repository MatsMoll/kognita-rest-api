//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore
import FluentPostgreSQL

public struct TaskDiscussionResponseAPIController: TaskDiscussionResponseAPIControlling {

    let repositories: RepositoriesRepresentable

    public var repository: TaskDiscussionRepositoring { repositories.taskDiscussionRepository }

    public func create(on req: Request) throws -> EventLoopFuture<TaskDiscussionResponse.Create.Response> {

        return try req
            .content
            .decode(TaskDiscussionResponse.Create.Data.self)
            .and(result: req.requireAuthenticated(User.self))
            .flatMap(repository.respond)
            .transform(to: .init())
    }

    public func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussionResponse]> {

        let user = try req.requireAuthenticated(User.self)

        return try repository.responses(
            to: req.parameters.modelID(TaskDiscussion.self),
            for: user
        )
    }

    public func setRecentlyVisited(for user: User, on req: Request) throws -> EventLoopFuture<Bool> {
        try repository.setRecentlyVisited(for: req.requireAuthenticated())
    }
}

extension TaskDiscussionResponse {
    public typealias DefaultAPIController = TaskDiscussionResponseAPIController
}
