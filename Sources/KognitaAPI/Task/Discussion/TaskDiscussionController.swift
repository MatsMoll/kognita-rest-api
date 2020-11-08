//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore

public struct TaskDiscussionAPIController: TaskDiscussionAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<NoData> {
        req.repositories { repositories in
            try repositories.taskDiscussionRepository.create(from: req.content.decode(), by: req.auth.require())
        }
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Update.Response> {
        req.repositories { repositories in
            try repositories.taskDiscussionRepository.updateModelWith(
                id: req.parameters.get(TaskDiscussion.self),
                to: req.content.decode(),
                by: req.auth.require()
            )
        }
    }

    public func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        req.repositories { repositories in
            try repositories.taskDiscussionRepository.getDiscussions(in: req.parameters.get(GenericTask.self))
        }
    }

    public func getDiscussionsForUser(on req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        req.repositories { repositories in
            try repositories.taskDiscussionRepository.getUserDiscussions(for: req.auth.require())
        }
    }
}

extension TaskDiscussion {
    public typealias DefaultAPIController = TaskDiscussionAPIController
}
