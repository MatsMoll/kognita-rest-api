//
//  VaporTestable.swift
//  App
//
//  Created by Mats Mollestad on 08/11/2018.
//

import Vapor
import XCTest
import XCTVapor
import KognitaAPI
import KognitaCore
import KognitaCoreTestable
import FluentSQL

/// A class that setups a application in a testable enviroment and creates a connection to the database
class VaporTestCase: XCTestCase {
    
    enum Errors: Error {
        case badTest
    }
    
    var app: Application!

    var repositories: RepositoriesRepresentable { TestableRepositories.testable(with: app) }

    let standardHeaders: HTTPHeaders = ["Content-Type" : "application/json"]
    
    var envArgs: [String]?

    func modify(controllers: inout APIControllers) {}
    func modify(repositories: TestableRepositories) {}


    override func setUp() {
        super.setUp()
        app = try! Application.testable()
        self.resetDB()
        modify(repositories: TestableRepositories.testable(with: app))
    }

    func resetDB() {
        guard let database = app.databases.database(logger: app.logger, on: app.eventLoopGroup.next()) as? SQLDatabase else { fatalError() }
        try! database.raw("DROP SCHEMA public CASCADE").run().wait()
        try! database.raw("CREATE SCHEMA public").run().wait()
        try! database.raw("GRANT ALL ON SCHEMA public TO public").run().wait()
        try! app.autoMigrate().wait()
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
        app = nil
        TestableRepositories.reset()
        TestableControllers.reset()
    }

    func failableTest(line: UInt = #line, file: StaticString = #file, test: (() throws -> Void)) {
        do {
            try test()
        } catch {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }

    func throwsError<T: Error>(of type: T.Type, line: UInt = #line, file: StaticString = #file, test: () throws -> Void) {
        do {
            try test()
            XCTFail("Did not throw an error", file: file, line: line)
        } catch let error {
            switch error {
            case is T: return
            default: XCTFail(error.localizedDescription, file: file, line: line)
            }
        }
    }
}

extension XCTHTTPResponse {
    func has(statusCode: HTTPResponseStatus, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(status, statusCode, "The http status code should have been \(statusCode), but were \(status)", file: file, line: line)
    }

    func has(headerName: String, with value: String? = nil, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(self.headers.contains(name: headerName), file: file, line: line)
    }

    func has<T: Decodable>(content type: T.Type, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNoThrow(
            try content.decode(T.self),
            "Was not able to decode \(type) based on the reponse content",
            file: file,
            line: line
        )
    }
}
