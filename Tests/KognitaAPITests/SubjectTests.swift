//
//  SubjectTests.swift
//  App
//
//  Created by Mats Mollestad on 11/10/2018.
//

import Vapor
import XCTest
import Crypto
import Fluent
@testable import KognitaCore
import KognitaCoreTestable

extension Subject.Create.Data: Content {}

class SubjectTests: VaporTestCase {
    
    private let subjectPath = "api/subjects"
    
    
    // MARK: - GET /subjects
    
    func testGetAllSubjects() throws {

        let user = try User.create(on: app)
        _ = try Subject.create(creator: user, on: app)
        _ = try Subject.create(creator: user, on: app)

        let startSubjects = try Subject.DatabaseModel.query(on: app.db).all().wait()
        XCTAssert(startSubjects.count != 0, "There is no subjects in the database")

        try app.sendRequest(to: subjectPath, method: .GET, headers: standardHeaders, loggedInUser: user) { response in
            response.has(statusCode: .ok)
            let subjects = try response.content.decode([Subject].self)
            XCTAssertEqual(subjects.count, startSubjects.count)
        }
    }
    
    
    // MARK: - POST /subjects
    
    func testCreateSubject() throws {

        let user = try User.create(on: app)

        let requestBody = Subject.Create.Data(
            code: Subject.uniqueCode(),
            name: "OS",
            description: "Operativstystemer",
            category: "Tech"
        )

        try app.sendRequest(to: subjectPath, method: .POST, headers: standardHeaders, body: requestBody, loggedInUser: user) { response in
            let subject = try response.content.decode(Subject.self)
            response.has(statusCode: .ok)
            XCTAssertEqual(subject.name, requestBody.name)
            let currentSubjects = try Subject.DatabaseModel.query(on: self.app.db).filter(\.$name == requestBody.name).all().wait()

            XCTAssert(currentSubjects.isEmpty == false, "The new subject was not added")
        }
    }


    func testCreateSubjectWhenNotLoggedInError() throws {
        let requestBody = Subject.Create.Data(
            code: Subject.uniqueCode(),
            name: "OS",
            description: "Operativstystemer",
            category: "Something"
        )

        XCTAssert(try Subject.DatabaseModel.query(on: app.db)
            .filter(\.$name == requestBody.name)
            .all()
            .wait()
            .isEmpty == true, "There exists a subject with name: \(requestBody.name)")

        try app.sendRequest(to: subjectPath, method: .POST, headers: standardHeaders, body: requestBody) { response in
            response.has(statusCode: .unauthorized)

            let currentSubjects = try Subject.DatabaseModel.query(on: self.app.db).filter(\.$name == requestBody.name).all().wait()
            XCTAssert(currentSubjects.isEmpty == true, "The new subject was added, but should not have been")
        }
    }

    // MARK: - GET /subjects/:id
    
    func testGetSingleSubject() throws {
        let user = try User.create(on: app)
        let subject = try Subject.create(creator: user, on: app)
        _ = try Subject.create(creator: user, on: app)

        let uri = subjectPath + "/\(subject.id)"
        try app.sendRequest(to: uri, method: .GET, headers: standardHeaders, loggedInUser: user) { response in
            response.has(statusCode: .ok)

            let responseSubject = try response.content.decode(Subject.self)
            XCTAssert(responseSubject.name == subject.name, "The response subject name du not match the one retreving, returned \(responseSubject.name)")
            XCTAssert(responseSubject.id == subject.id, "The response subject id du not match the one retreving, returned \(responseSubject.id)")
            XCTAssert(responseSubject.category == subject.category, "The response subject category du not match the one retreving, returned \(responseSubject.category)")
        }
    }
    
    
    // MARK: - DELETE /subjects/:id
    
    /// Tests if it is possible to delete a subject
    func testDeleteSubject() throws {

        let user = try User.create(on: app)

        _ = try Subject.create(creator: user, on: app)
        let subjectToDelete = try Subject.create(creator: user, on: app)

        let startSubjects = try Subject.DatabaseModel.query(on: app.db).all().wait()

        let path = subjectPath + "/\(subjectToDelete.id)"
        try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders, loggedInUser: user) { response in
            response.has(statusCode: .ok)

            let currentSubjects = try Subject.DatabaseModel.query(on: self.app.db).all().wait()
            XCTAssert(currentSubjects.count == startSubjects.count - 1, "The amount of subject is incorrect, count: \(currentSubjects.count)")
        }
    }
    
    
    /// Tests if it is possible to delete when not being the creator of a subject
//    func testDeleteSubjectWhenNotCreator() throws {
//        let user = try User.create(on: app)
//        let creator = try User.create(on: app)
//
//        let subjectToDelete = try Subject.create(creator: creator, on: app)
//
//        let startSubjects = try Subject.query(on: app).all().wait()
//
//        let path = try subjectPath + "/\(subjectToDelete.requireID())"
//        let response = try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders, loggedInUser: user)
//        XCTAssert(response.http.status == .forbidden, "Not returning a forbidden status on delete: \(response.http.status)")
//
//        let currentSubjects = try Subject.query(on: app).all().wait()
//        XCTAssert(currentSubjects.count == startSubjects.count, "The amount of subject is incorrect, count: \(currentSubjects.count)")
//    }
    
    /// Tests if it is possible to delete when not being the creator of a subject
    func testDeleteSubjectWhenNotLoggedIn() throws {
        let creator = try User.create(on: app)
        let subjectToDelete = try Subject.create(creator: creator, on: app)

        let startSubjects = try Subject.DatabaseModel.query(on: app.db).all().wait()

        let path = subjectPath + "/\(subjectToDelete.id)"
        try app.sendRequest(to: path, method: .DELETE, headers: standardHeaders) { response in
            response.has(statusCode: .unauthorized)

            let currentSubjects = try Subject.DatabaseModel.query(on: self.app.db).all().wait()
            XCTAssert(currentSubjects.count == startSubjects.count, "The amount of subject is incorrect, count: \(currentSubjects.count)")
        }
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
