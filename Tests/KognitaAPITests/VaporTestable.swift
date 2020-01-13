//
//  VaporTestable.swift
//  App
//
//  Created by Mats Mollestad on 08/11/2018.
//

import Vapor
import XCTest
import FluentPostgreSQL


/// A class that setups a application in a testable enviroment and creates a connection to the database
class VaporTestCase: XCTestCase {
    
    enum Errors: Error {
        case badTest
    }
    
    lazy var app: Application = try! Application.testable(envArgs: self.envArgs)
    var conn: PostgreSQLConnection!
    
    let standardHeaders: HTTPHeaders = ["Content-Type" : "application/json"]
    
    var envArgs: [String]?
    
    
    override func setUp() {
        super.setUp()
        print("Running setup")
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdownGracefully { (error) in
            guard let error = error else { return }
            print("Error shuttingdown: \(error)")
        }
        conn.close()
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
