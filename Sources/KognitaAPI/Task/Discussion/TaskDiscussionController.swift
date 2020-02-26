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
{}

extension TaskDiscussion {
    public typealias DefaultAPIController = TaskDiscussionAPIController<TaskDiscussion.DatabaseRepository>
}
