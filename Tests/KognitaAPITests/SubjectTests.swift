//
//  SubjectTests.swift
//  App
//
//  Created by Mats Mollestad on 11/10/2018.
//

import Vapor
import XCTest
import FluentPostgreSQL
import Crypto
@testable import KognitaCore
import KognitaCoreTestable

class SubjectTests: VaporTestCase {
    
    private let subjectPath = "api/subjects"
    
    
    // MARK: - GET /subjects
    
    func testGetAllSubjects() throws {

        let user = try User.create(on: conn)
        _ = try Subject.create(creator: user, on: conn)
        _ = try Subject.create(creator: user, on: conn)

        let startSubjects = try Subject.query(on: conn).all().wait()
        XCTAssert(startSubjects.count != 0, "There is no subjects in the database")

        let response = try app.sendRequest(to: subjectPath, method: .GET, headers: standardHeaders, loggedInUser: user)
        XCTAssert(response.http.status == .ok, "This should not return an error")

        let subjects = try response.content.syncDecode([Subject].self)
        XCTAssert(subjects.count == startSubjects.count, "There should be two subjects, but there were: \(subjects.count)")
    }
    
    
    // MARK: - POST /subjects
    
    func testCreateSubject() throws {

        let user = try User.create(on: conn)

        let requestBody = Subject.Create.Data(
            name: "OS",
            colorClass: .primary,
            description: "Operativstystemer",
            category: "Tech"
        )

        let response = try app.sendRequest(to: subjectPath, method: .POST, headers: standardHeaders, body: requestBody, loggedInUser: user)
        let subject = try response.content.syncDecode(Subject.self)

        XCTAssert(response.http.status == .ok, "There was an error when posting a new subject: \(response.http.status)")
        XCTAssert(subject.name == requestBody.name, "The saved subject has a different .name")
        XCTAssert(subject.colorClass == requestBody.colorClass, "The saved subject has a different .code")
        XCTAssert(subject.creatorId == user.id, "The creatorId is incorrect: \(subject.creatorId)")

        let currentSubjects = try Subject.query(on: conn).filter(\.name == requestBody.name).all().wait()

        XCTAssert(currentSubjects.isEmpty == false, "The new subject was not added")
    }


    func testCreateSubjectWhenNotLoggedInError() throws {
        let requestBody = Subject.Create.Data(
            name: "OS",
            colorClass: .primary,
            description: "Operativstystemer",
            category: "Something"
        )

        XCTAssert(try Subject.query(on: conn)
            .filter(\.name == requestBody.name)
            .all()
            .wait()
            .isEmpty == true, "There exists a subject with name: \(requestBody.name)")

        XCTAssertThrowsError(
            try app.sendRequest(to: subjectPath, method: .POST, headers: standardHeaders, body: requestBody)
        )

        let currentSubjects = try Subject.query(on: conn).filter(\.name == requestBody.name).all().wait()
        XCTAssert(currentSubjects.isEmpty == true, "The new subject was added, but should not have been")
    }

    // MARK: - GET /subjects/:id
    
    func testGetSingleSubject() throws {
        let user = try User.create(on: conn)
        let subject = try Subject.create(creator: user, on: conn)
        _ = try Subject.create(creator: user, on: conn)

        let uri = try subjectPath + "/\(subject.requireID())"
        let response = try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user)
        XCTAssert(response.http.status == .ok, "This should not return an error")

        let responseSubject = try response.content.syncDecode(Subject.self)
        XCTAssert(responseSubject.name == subject.name, "The response subject name du not match the one retreving, returned \(responseSubject.name)")
        try XCTAssert(responseSubject.requireID() == subject.requireID(), "The response subject id du not match the one retreving, returned \(try! responseSubject.requireID())")
        XCTAssert(responseSubject.category == subject.category, "The response subject category du not match the one retreving, returned \(responseSubject.category)")
    }
    
    
    // MARK: - DELETE /subjects/:id
    
    /// Tests if it is possible to delete a subject
    func testDeleteSubject() throws {

        let user = try User.create(on: conn)

        _ = try Subject.create(creator: user, on: conn)
        let subjectToDelete = try Subject.create(creator: user, on: conn)

        let startSubjects = try Subject.query(on: conn).all().wait()

        let path = try subjectPath + "/\(subjectToDelete.requireID())"
        let response = try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders, loggedInUser: user)
        XCTAssert(response.http.status == .ok, "Not returning an ok status on delete: \(response.http.status)")

        let currentSubjects = try Subject.query(on: conn).all().wait()
        XCTAssert(currentSubjects.count == startSubjects.count - 1, "The amount of subject is incorrect, count: \(currentSubjects.count)")
    }
    
    
    /// Tests if it is possible to delete when not being the creator of a subject
//    func testDeleteSubjectWhenNotCreator() throws {
//        let user = try User.create(on: conn)
//        let creator = try User.create(on: conn)
//
//        let subjectToDelete = try Subject.create(creator: creator, on: conn)
//
//        let startSubjects = try Subject.query(on: conn).all().wait()
//
//        let path = try subjectPath + "/\(subjectToDelete.requireID())"
//        let response = try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders, loggedInUser: user)
//        XCTAssert(response.http.status == .forbidden, "Not returning a forbidden status on delete: \(response.http.status)")
//
//        let currentSubjects = try Subject.query(on: conn).all().wait()
//        XCTAssert(currentSubjects.count == startSubjects.count, "The amount of subject is incorrect, count: \(currentSubjects.count)")
//    }
    
    /// Tests if it is possible to delete when not being the creator of a subject
    func testDeleteSubjectWhenNotLoggedIn() throws {
        let creator = try User.create(on: conn)
        let subjectToDelete = try Subject.create(creator: creator, on: conn)

        let startSubjects = try Subject.query(on: conn).all().wait()

        let path = try subjectPath + "/\(subjectToDelete.requireID())"
        XCTAssertThrowsError(
            try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders)
        )
        let currentSubjects = try Subject.query(on: conn).all().wait()
        XCTAssert(currentSubjects.count == startSubjects.count, "The amount of subject is incorrect, count: \(currentSubjects.count)")
    }
    
    
    static let allTests = [
        ("testGetAllSubjects", testGetAllSubjects),
        ("testCreateSubject", testCreateSubject),
        ("testCreateSubjectWhenNotLoggedInError", testCreateSubjectWhenNotLoggedInError),
        ("testGetSingleSubject", testGetSingleSubject),
        ("testDeleteSubject", testDeleteSubject),
//        ("testDeleteSubjectWhenNotCreator", testDeleteSubjectWhenNotCreator),
        ("testDeleteSubjectWhenNotLoggedIn", testDeleteSubjectWhenNotLoggedIn)
    ]
}
