//
//  TaskDiscussionTests.swift
//  KognitaAPITests
//
//  Created by Eskild Brobak on 17/03/2020.
//

import Foundation
import XCTest
@testable import KognitaCore
import KognitaCoreTestable

class TaskDiscussionTests: VaporTestCase {

    func testCreateDiscussion() {
        do {
            let user = try User.create(on: conn)
            let task = try Task.create(on: conn)

            let data = TaskDiscussion.Create.Data(
                description: "test",
                taskID: try task.requireID()
            )
            // Create task discussion request
            let response = try app.sendRequest(to: "/api/task-discussion", method: .POST, headers: standardHeaders, body: data, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: TaskDiscussion.Create.Response.self)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateTaskDiscussionResponse() {
        do {
            let user = try User.create(on: conn)
            let discussion = try TaskDiscussion.create(on: conn)

            let data = TaskDiscussion.Pivot.Response.Create.Data(
                response: "test",
                discussionID: try discussion.requireID()
            )

            // Create task discussion reponse request
            let response = try app.sendRequest(to: "/api/task-discussion-response", method: .POST, headers: standardHeaders, body: data, loggedInUser: user)

            response.has(statusCode: .ok)
            response.has(content: TaskDiscussion.Pivot.Response.Create.Response.self)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static let allTests = [
        ("testCreateDiscussion", testCreateDiscussion),
        ("testCreateTaskDiscussionResponse", testCreateTaskDiscussionResponse)
    ]
}
