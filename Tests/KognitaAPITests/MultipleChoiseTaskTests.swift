//
//  MultipleChoiseTaskTests.swift
//  AppTests
//
//  Created by Mats Mollestad on 10/11/2018.
//

import Vapor
import XCTest
import FluentPostgreSQL
@testable import KognitaCore
import KognitaCoreTestable

class MultipleChoiseTaskTests: VaporTestCase {

    var uri: String {
        return "api/tasks/multiple-choise"
    }
    
    func testDeleteTaskInstance() throws {
        let user                = try User.create(on: conn)
        let subtopic            = try Subtopic.create(on: conn)
        _                       = try Task.create(on: conn)
        let task                = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)
        _                       = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)

        let uri                 = try self.uri + "/\(task.id)"
        let response            = try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders, loggedInUser: user)
        XCTAssert(response.http.status  == .ok,     "Expexted a ok response, but got \(response.http.status)")

        let databaseTask        = try Task.find(task.id, on: conn).wait()
        let databaseMultiple    = try MultipleChoiceTask.DatabaseModel.find(task.id, on: conn).wait()

        XCTAssert(databaseTask == nil, "The Task instance was not marked as outdated")
        XCTAssert(databaseMultiple != nil, "The MultipleChoiseTask instance was deleted")
    }
    
    func testDeleteTaskInstanceNotLoggedInError() throws {
        let subtopic            = try Subtopic.create(on: conn)
        _                       = try Task.create(on: conn)
        let task                = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)
        _                       = try MultipleChoiceTask.create(subtopic: subtopic, on: conn)

        let uri                 = try self.uri + "/\(task.id)"
        let response = try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders)
        response.has(statusCode: .unauthorized)
        
        let databaseTask        = try Task.find(task.id, on: conn).wait()
        let databaseMultiple    = try MultipleChoiceTask.DatabaseModel.find(task.id, on: conn).wait()

        XCTAssert(databaseTask          != nil,             "The Task instance was deleted")
        XCTAssert(databaseMultiple      != nil,             "The MultipleChoiseTask instance was deleted")
    }
    
    static let allTests = [
        ("testDeleteTaskInstance", testDeleteTaskInstance),
        ("testDeleteTaskInstanceNotLoggedInError", testDeleteTaskInstanceNotLoggedInError)
    ]
}
