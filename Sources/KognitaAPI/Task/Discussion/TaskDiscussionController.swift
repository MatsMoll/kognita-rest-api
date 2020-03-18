//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore
import FluentPostgreSQL

public class TaskDiscussionAPIController
    <Repository: TaskDiscussionRepositoring>:
    TaskDiscussionAPIControlling
{
    public static func get(discussions req: Request) throws -> EventLoopFuture<[TaskDiscussion.Details]> {
        return req.parameters
            .model(Task.self, on: req)
            .flatMap { task in
                try Repository.getDiscussions(in: task.requireID(), on: req)
        }
    }
}

extension TaskDiscussion {
    public typealias DefaultAPIController = TaskDiscussionAPIController<TaskDiscussion.DatabaseRepository>
}