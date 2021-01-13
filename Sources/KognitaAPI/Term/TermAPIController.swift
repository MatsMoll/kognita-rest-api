//
//  File.swift
//  
//
//  Created by Mats Mollestad on 12/01/2021.
//

import Vapor
import KognitaModels

extension Term: ModelParameterRepresentable {}
extension Term: Content {}

public protocol TermAPIController: RouteCollection {
    func termWithID(on req: Request) throws -> EventLoopFuture<Term>
    
    func create(on req: Request) throws -> EventLoopFuture<Term.ID>
    
    func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension TermAPIController {
    
    public func boot(routes: RoutesBuilder) throws {
        
        let terms = routes.grouped("terms")
        let termInstance = terms.grouped(Term.parameter)
        
        terms.post(use: create(on:))
        
        termInstance.delete(use: delete(on:))
        termInstance.get(use: termWithID(on: ))
    }
}


struct DefaultTermAPIController: TermAPIController {
    
    func create(on req: Request) throws -> EventLoopFuture<Term.ID> {
        let term = try req.content.decode(Term.Create.Data.self)
        return req.repositories { repo in
            repo.termRepository.create(term: term)
        }
    }
    
    func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let termID = try req.parameters.get(Term.self)
        return req.repositories { repo in
            repo.termRepository.deleteTermWith(id: termID)
        }
        .transform(to: .ok)
    }
    
    func termWithID(on req: Request) throws -> EventLoopFuture<Term> {
        let termID = try req.parameters.get(Term.self)
        return req.repositories { repo in
            repo.termRepository.with(id: termID)
        }
    }
}
