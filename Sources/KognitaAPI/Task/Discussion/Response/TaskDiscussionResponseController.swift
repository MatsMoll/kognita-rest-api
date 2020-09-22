//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore

public struct TaskDiscussionResponseAPIController: TaskDiscussionResponseAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<TaskDiscussionResponse.Create.Response> {

        try req.repositories.taskDiscussionRepository.respond(with: req.content.decode(TaskDiscussionResponse.Create.Data.self), by: req.auth.require())
            .transform(to: .init())
    }

    public func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussionResponse]> {

        return try req.repositories.taskDiscussionRepository.responses(
            to: req.parameters.get(TaskDiscussion.self),
            for: req.auth.require()
        )
    }

    public func setRecentlyVisited(on req: Request) throws -> EventLoopFuture<Bool> {
        try req.repositories.taskDiscussionRepository.setRecentlyVisited(for: req.auth.require())
    }
}

extension TaskDiscussionResponse {
    public typealias DefaultAPIController = TaskDiscussionResponseAPIController
}
