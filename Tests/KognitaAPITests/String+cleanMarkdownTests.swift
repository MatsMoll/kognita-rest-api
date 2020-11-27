//
//  String+cleanMarkdownTests.swift
//  KognitaAPITests
//
//  Created by Mats Mollestad on 27/11/2020.
//

import Foundation
@testable import KognitaAPI
import XCTest

class CleanMarkdownTests: XCTestCase {
    
    func testSimpleMarkdown() throws {
        let markdown =
            """
            # hello there
            Lets add some math $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$. Nice!
            """
        let expectedResult = "hello there Lets add some math . Nice!"
        try XCTAssertEqual(markdown.cleanMarkdown(), expectedResult)
    }
    
    func testMathNewLineSeperationMarkdown() throws {
        let markdown =
            """
            # hello there
            Lets add some math $$\\frac{1}{2} +
            \\sum_{i=n}^\\infinity n$$. Nice!
            """
        let expectedResult =
            """
            hello there Lets add some math $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$. Nice!
            """
        try XCTAssertEqual(markdown.cleanMarkdown(), expectedResult)
    }
    
    func testMultipleMathInMarkdown() throws {
        let markdown =
            """
            # hello there
            Lets add some math $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$. Nice!
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n
            """
        let expectedResult = "hello there Lets add some math . Nice! $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n"
        try XCTAssertEqual(markdown.cleanMarkdown(), expectedResult)
    }
    
    func testMultipleMathInAsLastMarkdown() throws {
        let markdown =
            """
            # hello there
            Lets add some math $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$. Nice!
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$
            $$\\frac{1}{2} + \\sum_{i=n}^\\infinity n$$
            """
        let expectedResult = "hello there Lets add some math . Nice!"
        try XCTAssertEqual(markdown.cleanMarkdown(), expectedResult)
    }
}
