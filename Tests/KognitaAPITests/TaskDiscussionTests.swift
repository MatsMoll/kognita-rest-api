//
//  TaskDiscussionTests.swift
//  KognitaAPITests
//
//  Created by Eskild Brobak on 17/03/2020.
//

import Foundation
import XCTest
import Vapor
@testable import KognitaCore
import KognitaCoreTestable

extension TaskDiscussion.Create.Data: Content {}
extension TaskDiscussionResponse.Create.Data: Content {}

class TaskDiscussionTests: VaporTestCase {

    func testCreateDiscussion() throws {
        let user = try User.create(on: app)
        let task = try TaskDatabaseModel.create(on: app)

        let data = TaskDiscussion.Create.Data(
            description: "test",
            taskID: try task.requireID()
        )
        // Create task discussion request
        try app.sendRequest(to: "/api/task-discussion", method: .POST, headers: standardHeaders, body: data, loggedInUser: user) { response in

            response.has(statusCode: .ok)
            response.has(content: TaskDiscussion.Create.Response.self)
        }
    }

    func testCreateTaskDiscussionResponse() throws {
        let user = try User.create(on: app)
        let discussion = try TaskDiscussion.create(on: app)

        let data = TaskDiscussionResponse.Create.Data(
            response: "test",
            discussionID: try discussion.requireID()
        )

        // Create task discussion reponse request
        try app.sendRequest(to: "/api/task-discussion-response", method: .POST, headers: standardHeaders, body: data, loggedInUser: user) { response in
            response.has(statusCode: .ok)
            response.has(content: TaskDiscussionResponse.Create.Response.self)
        }
    }

    static let allTests = [
        ("testCreateDiscussion", testCreateDiscussion),
        ("testCreateTaskDiscussionResponse", testCreateTaskDiscussionResponse)
    ]
}
