//
//  TaskDiscussionController.swift
//  KognitaAPI
//
//  Created by Eskild Brobak on 26/02/2020.
//

import Vapor
import KognitaCore
import FluentPostgreSQL

public class TaskDiscussionResponseAPIController
    <Repository: TaskDiscussionRepositoring>:
    TaskDiscussionResponseAPIControlling {
    public static func create(on req: Request) throws -> EventLoopFuture<TaskDiscussion.Pivot.Response.Create.Response> {

        let user = try req.requireAuthenticated(User.self)

        return try req
            .content
            .decode(TaskDiscussion.Pivot.Response.Create.Data.self)
            .map { respons in

                return try Repository.respond(
                    with: respons,
                    by: user,
                    on: req)
        }
        .transform(to: .init())

    }

    public static func get(responses req: Request) throws -> EventLoopFuture<[TaskDiscussion.Pivot.Response.Details]> {

        return req.parameters
            .model(TaskDiscussion.self, on: req)
            .flatMap { discussion in
                try Repository.responses(to: discussion.requireID(), on: req)
        }
    }

}

extension TaskDiscussion.Pivot.Response {
    public typealias DefaultAPIController = TaskDiscussionResponseAPIController<TaskDiscussion.DatabaseRepository>
}
