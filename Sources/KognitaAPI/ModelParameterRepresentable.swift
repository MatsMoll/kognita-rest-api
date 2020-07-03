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
    public func get<Model: ModelParameterRepresentable>(_ parameter: Model.Type) throws -> Model.ID {
        guard
            let idValue = self.get(Model.identifier),
            let id = Model.ID.expressed(by: idValue)
        else { throw Abort(.badRequest) }
        return id
    }
}
