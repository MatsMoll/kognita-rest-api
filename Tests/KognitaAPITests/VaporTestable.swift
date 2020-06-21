//
//  VaporTestable.swift
//  App
//
//  Created by Mats Mollestad on 08/11/2018.
//

import Vapor
import XCTest
import FluentPostgreSQL
import KognitaAPI
import KognitaCore
import KognitaCoreTestable

/// A class that setups a application in a testable enviroment and creates a connection to the database
class VaporTestCase: XCTestCase {
    
    enum Errors: Error {
        case badTest
    }
    
    lazy var app: Application = try! Application.testable(envArgs: self.envArgs)
    var connectionPool: DatabaseConnectionPool<ConfiguredDatabase<PostgreSQLDatabase>>!
    var conn: PostgreSQLConnection { try! connectionPool.requestConnection().wait() }
    var repositories: RepositoriesRepresentable { try! app.make() }
    
    let standardHeaders: HTTPHeaders = ["Content-Type" : "application/json"]
    
    var envArgs: [String]?

    func modify(controllers: inout APIControllers) {}
    func modify(repositories: inout TestableRepositories) {}
    
    
    override func setUp() {
        super.setUp()
        print("Running setup")
        try! Application.reset()
        app = try! Application.testable()
        connectionPool = try! app.connectionPool(to: .psql)
        TestableRepositories.modifyRepositories(modify(repositories:))
        TestableControllers.modifyControllers(modify(controllers:))
    }
    
    override func tearDown() {
        super.tearDown()
        TestableRepositories.reset()
        TestableControllers.reset()
        app.shutdownGracefully { (error) in
            guard let error = error else { return }
            print("Error shuttingdown: \(error)")
        }
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


extension Response {
    func has(statusCode: HTTPResponseStatus, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(http.status, statusCode, "The http status code should have been \(statusCode), but were \(http.status)", file: file, line: line)
    }

    func has(headerName: String, with value: String? = nil, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(self.http.headers.contains(name: headerName), file: file, line: line)
    }

    func has<T: Decodable>(content type: T.Type, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNoThrow(
            try content.syncDecode(T.self),
            "Was not able to decode \(type) based on the reponse content",
            file: file,
            line: line
        )
    }
}
