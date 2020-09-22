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
        try req.create(in: req.repositories.taskDiscussionRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Update.Response> {
        try req.update(with: req.repositories.taskDiscussionRepository.updateModelWith(id: to: by: ), parameter: TaskDiscussion.self)
    }

    public func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        try req.repositories.taskDiscussionRepository.getDiscussions(in: req.parameters.get(GenericTask.self))
    }

    public func getDiscussionsForUser(on req: Request) throws -> EventLoopFuture<[TaskDiscussion]> {
        try req.repositories.taskDiscussionRepository.getUserDiscussions(for: req.auth.require())
    }
}

extension TaskDiscussion {
    public typealias DefaultAPIController = TaskDiscussionAPIController
}
