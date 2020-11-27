//
//  ModelParameterRepresentable.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 02/07/2020.
//

import Vapor

public protocol MayBeExpressibleByStringLiteral {
    static func expressed(by string: String) -> Self?
}

extension Int: MayBeExpressibleByStringLiteral {
    public static func expressed(by string: String) -> Int? { Int(string) }
}

public protocol ModelParameterRepresentable {
    associatedtype ID: MayBeExpressibleByStringLiteral
    static var identifier: String { get }
    static var parameter: PathComponent { get }
}

extension ModelParameterRepresentable {
    public static var identifier: String { String(reflecting: Self.self) }
    public static var parameter: PathComponent { .parameter(identifier) }
}

extension Parameters {
    /// Convert a parameter to a model id
    /// - Parameter parameter: The parameter tyåe to decode
    /// - Throws: If the type is either wrong or if the value is invalid
    /// - Returns: The id of the model
    public func get<Model: ModelParameterRepresentable>(_ parameter: Model.Type) throws -> Model.ID {
        guard let idValue = self.get(Model.identifier) else { throw Abort(.internalServerError, reason: "Unable to find parameter of \(parameter)")}
        guard let id = Model.ID.expressed(by: idValue) else { throw Abort(.badRequest, reason: "Unable to decode parameter to \(Model.ID.self)") }
        return id
    }
}
