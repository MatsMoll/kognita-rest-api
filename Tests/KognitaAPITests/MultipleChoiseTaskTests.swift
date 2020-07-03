//
//  MultipleChoiseTaskTests.swift
//  AppTests
//
//  Created by Mats Mollestad on 10/11/2018.
//

import Vapor
import XCTest
@testable import KognitaCore
import KognitaCoreTestable

class MultipleChoiseTaskTests: VaporTestCase {

    var uri: String {
        return "/api/tasks/multiple-choise"
    }
    
    func testDeleteTaskInstance() throws {
        let user                = try User.create(on: app)
        let subtopic            = try Subtopic.create(on: app)
        _                       = try TaskDatabaseModel.create(on: app)
        let task                = try MultipleChoiceTask.create(subtopic: subtopic, on: app)
        _                       = try MultipleChoiceTask.create(subtopic: subtopic, on: app)

        let uri                 = self.uri + "/\(task.id)"
        try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders, loggedInUser: user) { response in

            response.has(statusCode: .ok)

            let databaseTask        = try TaskDatabaseModel.find(task.id, on: self.app.db).wait()
            let databaseMultiple    = try MultipleChoiceTask.DatabaseModel.find(task.id, on: self.app.db).wait()

            XCTAssert(databaseTask == nil, "The Task instance was not marked as outdated")
            XCTAssert(databaseMultiple != nil, "The MultipleChoiseTask instance was deleted")
        }
    }
    
    func testDeleteTaskInstanceNotLoggedInError() throws {
        let subtopic            = try Subtopic.create(on: app)
        _                       = try TaskDatabaseModel.create(on: app)
        let task                = try MultipleChoiceTask.create(subtopic: subtopic, on: app)
        _                       = try MultipleChoiceTask.create(subtopic: subtopic, on: app)

        let uri                 = self.uri + "/\(task.id)"
        try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders) { response in
            response.has(statusCode: .unauthorized)

            let databaseTask        = try TaskDatabaseModel.find(task.id, on: self.app.db).wait()
            let databaseMultiple    = try MultipleChoiceTask.DatabaseModel.find(task.id, on: self.app.db).wait()

            XCTAssert(databaseTask          != nil,             "The Task instance was deleted")
            XCTAssert(databaseMultiple      != nil,             "The MultipleChoiseTask instance was deleted")
        }
    }
    
    static let allTests = [
        ("testDeleteTaskInstance", testDeleteTaskInstance),
        ("testDeleteTaskInstanceNotLoggedInError", testDeleteTaskInstanceNotLoggedInError)
    ]
}
