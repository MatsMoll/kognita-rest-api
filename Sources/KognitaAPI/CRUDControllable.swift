//
//  CRUDControllable.swift
//  App
//
//  Created by Mats Mollestad on 09/11/2018.
//

import Vapor
import KognitaCore

/// A protocol simplefying CRUD controllers
protocol CRUDControllable {

    associatedtype Model : Content

    /// Returns a collection of a model type
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     A collection of a model type
    func getInstanceCollection(_ req: Request) throws -> Future<[Model]>

    /// Returns a single model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     A single model object
    func getInstance(_ req: Request) throws -> Future<Model>

    /// Creates a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     The new model object
    func create(_ req: Request) throws -> Future<Model>

    /// Deletes a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     A status enum indication if it was sucessfull
    func delete(_ req: Request) throws -> Future<HTTPStatus>

    /// Edits a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     The edited model object
    func edit(_ req: Request) throws -> Future<Model>

    /// The models parameter representation
    var parameter: PathComponentsRepresentable { get }
}

/// An extension that makes it easier to use the protocol
extension CRUDControllable where Model: Parameter {
    var parameter: PathComponentsRepresentable { return Model.parameter }
}


/// A protocol simplefying CRUD controllers
protocol KognitaCRUDControllable {

    associatedtype Model : KognitaCRUDModel
    associatedtype ResponseContent : Content

    /// Creates a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     The new model object
    static func create(_ req: Request) throws -> Future<ResponseContent>

    /// Deletes a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     A status enum indication if it was sucessfull
    static func delete(_ req: Request) throws -> Future<HTTPStatus>

    /// Edits a model object
    ///
    /// - Parameter req:
    ///     The request sendt
    ///
    /// - Returns:
    ///     The edited model object
    static func edit(_ req: Request) throws -> Future<ResponseContent>
    
    /// Returns the Model
    ///
    /// - Parameter req: The `Request` sendt to the server
    ///
    /// - Returns: A `Future<ResponseContent>`
    static func get(_ req: Request) throws -> Future<ResponseContent>
    
    /// Returns all of the `Model`s
    ///
    /// - Parameter req: The `Request` sendt to the server
    ///
    /// - Returns: A `Future<ResponseContent>`
    static func getAll(_ req: Request) throws -> Future<[ResponseContent]>
    
    
    /// Maps a `Model` to a `ResponseContent`
    ///
    /// - Parameters:
    ///     - model: The `Model` to map
    ///     - conn: A database connection
    ///
    /// - Returns: A `Future<ResponseContent>`
    static func map(model: Model, on conn: DatabaseConnectable) throws -> Future<ResponseContent>
    
    /// Maps a `Model.Create.Response` to a `ResponseContent`
    ///
    /// - Parameters:
    ///     - model: The `Model.Create.Response` to map
    ///     - conn: A database connection
    ///
    /// - Returns: A `Future<ResponseContent>`
    static func mapCreate(response: Model.Create.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent>
    
    /// Maps a `Model.Edit.Response` to a `ResponseContent`
    ///
    /// - Parameters:
    ///     - model: The `Model.Edit.Response` to map
    ///     - conn: A database connection
    ///
    /// - Returns: A `Future<ResponseContent>`
    static func mapEdit(response: Model.Edit.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent>

    /// The models parameter representation
    static var parameter: PathComponentsRepresentable { get }
}

extension KognitaCRUDControllable where Model == ResponseContent {
    static func map(model: Model, on conn: DatabaseConnectable) throws -> Future<ResponseContent> {
        return conn.future(model)
    }
}

extension KognitaCRUDControllable where Model.Create.Response == ResponseContent, Model == Model.Create.Response {
    static func mapCreate(response: Model.Create.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent> {
        return conn.future(response)
    }
}

extension KognitaCRUDControllable where Model == Model.Create.Response {
    static func mapCreate(response: Model.Create.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent> {
        return try Self.map(model: response, on: conn)
    }
}

extension KognitaCRUDControllable where Model.Create.Response == ResponseContent {
    static func mapCreate(response: Model.Create.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent> {
        return conn.future(response)
    }
}

extension KognitaCRUDControllable where Model.Create.Response == Model.Edit.Response {
    static func mapEdit(response: Model.Edit.Response, on conn: DatabaseConnectable) throws -> Future<ResponseContent> {
        return try Self.mapCreate(response: response, on: conn)
    }
}

extension KognitaCRUDControllable where Model.Create.Data : Decodable {
    
    static func create(_ req: Request) throws -> Future<ResponseContent> {
        
        let user = try req.authenticated(User.self)
        
        return try req.content
            .decode(Model.Create.Data.self)
            .flatMap { content in
                
                try Model.Repository
                    .create(from: content, by: user, on: req)
                    .flatMap { try Self.mapCreate(response: $0, on: req) }
        }
    }
}

/// An extension that makes it easier to use the protocol
extension KognitaCRUDControllable where Model: Parameter, Model.ResolvedParameter == Future<Model> {
    
    static var parameter: PathComponentsRepresentable { return Model.parameter }
    
    static func delete(_ req: Request) throws -> Future<HTTPStatus> {
        
        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(Model.self)
            .flatMap { model in

                try Model.Repository
                    .delete(model, by: user, on: req)
                    .transform(to: .ok)
        }
    }
    
    static func get(_ req: Request) throws -> Future<ResponseContent> {

        return try req.parameters
            .next(Model.self)
            .flatMap { try Self.map(model: $0, on: req) }
    }
}

/// An extension that makes it easier to use the protocol
extension KognitaCRUDControllable where Model: Parameter, Model.ResolvedParameter == Future<Model>, Model.Edit.Data : Decodable {
    
    static func edit(_ req: Request) throws -> Future<ResponseContent> {
        
        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(Model.Edit.Data.self)
            .flatMap { content in
                
                try req.parameters
                    .next(Model.self)
                    .flatMap { model in
                        
                        try Model.Repository
                            .edit(model, to: content, by: user, on: req)
                            .flatMap { try Self.mapEdit(response: $0, on: req) }
                }
        }
    }
}

protocol KognitaModelRenderable {
    associatedtype Pages
}

protocol KognitaWebController {
    
    associatedtype Model : KognitaPersistenceModel
    
    func create(on req: Request) throws -> Future<HTTPResponse>
}
