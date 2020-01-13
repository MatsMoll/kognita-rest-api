//
//  TopicTests.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/10/2018.
//

import XCTest
import Vapor
import FluentPostgreSQL
import KognitaCore
import KognitaCoreTestable


class TopicTests: VaporTestCase {
    
    private let path = "api/topics/"

    
    func testGetAllTopics() throws {

        TopicRepositoryMock.Logger.shared.clear()

        let user                = try User.create(on: conn)
        let topic               = try Topic.create(on: conn)

        let uri                 = "api/subjects/\(topic.subjectId)/topics"
        let response            = try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user)

        response.has(statusCode: .ok)
        response.has(content: [Topic].self)

        let latestLog = try XCTUnwrap(TopicRepositoryMock.Logger.shared.logs.last)

        switch latestLog {
        case .getTopics(let subject):
            XCTAssertEqual(subject.id, topic.subjectId)
        default:
            XCTFail("Incorrect log entry")
        }
    }
    
    
    func testGetTopicsWhenNotLoggedInError() throws {

        let topic       = try Topic.create(on: conn)
        _               = try Topic.create(chapter: 2, subjectId: topic.subjectId, on: conn)
        _               = try Topic.create(on: conn)

        let response = try app.sendRequest(to: path, method: .GET, headers: standardHeaders)
        response.has(statusCode: .unauthorized)
    }
    
    // MARK: - GET /topics/:id
    
    func testGetTopicWithId() throws {

        let user            = try User.create(on: conn)
        let topic           = try Topic.create(on: conn)
        _                   = try Topic.create(chapter: 2, subjectId: topic.subjectId, on: conn)

        let uri             = try path + "\(topic.requireID())"
        let response        = try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user)

        response.has(statusCode: .ok)
        response.has(content: Topic.self)
    }
    
    
    func testGetTopicWithIdWhenNotLoggedInError() throws {

        let topic           = try Topic.create(on: conn)
        _                   = try Topic.create(chapter: 2, subjectId: topic.subjectId, on: conn)

        let uri             = try path + "\(topic.requireID())"
        let response = try app.sendRequest(to: uri, method: .GET, headers: standardHeaders)
        response.has(statusCode: .unauthorized)
    }
    
    
    // MARK: - DELETE /subjects/:id/topics/:id
    
    func testDeleteingTopic() throws {
        let user            = try User.create(on: conn)
        let topic           = try Topic.create(creator: user, on: conn)
        _                   = try Topic.create(chapter: 2, subjectId: topic.subjectId, on: conn)

        let uri             = try path + "\(topic.requireID())"
        let response        = try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders, loggedInUser: user)
        XCTAssert(response.http.status  == .ok, "The http statuscode should have been ok, but were \(response.http.status)")

        let databaseTopic   = try Topic.find(topic.requireID(), on: conn).wait()
        XCTAssert(databaseTopic         == nil, "The topic should be deleted, but still exists in the database")
    }
    
//    func testDeleteingTopicWhenNotCreatorError() throws {
//        let user            = try User.create(on: conn)
//        let topic           = try Topic.create(on: conn)
//        _                   = try Topic.create(chapter: 2, creatorId: topic.creatorId, subjectId: topic.subjectId, on: conn)
//
//        let uri             = try path + "\(topic.requireID())"
//        let response        = try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders, loggedInUser: user)
//        XCTAssert(response.http.status  == .forbidden, "The http statuscode should have been forbidden, but were \(response.http.status)")
//
//        let databaseTopic   = try Topic.find(topic.requireID(), on: conn).wait()
//        XCTAssert(databaseTopic         != nil, "The topic should NOT be deleted, but the topic is not in the database")
//    }
    
    func testDeleteingTopicWhenNotLoggedInError() throws {
        let topic           = try Topic.create(on: conn)
        _                   = try Topic.create(chapter: 2, subjectId: topic.subjectId, on: conn)

        let uri             = try path + "\(topic.requireID())"

        let response = try app.sendRequest(to: uri, method: .DELETE, headers: standardHeaders)
        response.has(statusCode: .ok)
        let databaseTopic = try Topic.find(topic.requireID(), on: conn).wait()
        XCTAssert(databaseTopic != nil,             "The topic should NOT be deleted, but the topic is not in the database")
    }
    
    static let allTests = [
        ("testGetAllTopics", testGetAllTopics),
        ("testGetTopicsWhenNotLoggedInError", testGetTopicsWhenNotLoggedInError),
        ("testGetTopicWithId", testGetTopicWithId),
        ("testGetTopicWithIdWhenNotLoggedInError", testGetTopicWithIdWhenNotLoggedInError),
        ("testDeleteingTopic", testDeleteingTopic),
        ("testDeleteingTopicWhenNotLoggedInError", testDeleteingTopicWhenNotLoggedInError)
    ]
}
