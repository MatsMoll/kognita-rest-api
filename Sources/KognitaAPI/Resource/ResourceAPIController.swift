//
//  ResourceAPIController.swift
//  
//
//  Created by Mats Mollestad on 06/01/2021.
//

import Foundation
import Vapor
import KognitaModels

public protocol ResourceAPIController: RouteCollection {
    
    func createVideo(on req: Request) throws -> EventLoopFuture<Resource.ID>
    func createBook(on req: Request) throws -> EventLoopFuture<Resource.ID>
    func createArticle(on req: Request) throws -> EventLoopFuture<Resource.ID>

    func connectSubtopicToResource(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func disconnectSubtopicFromResource(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func resourcesForSubtopic(on req: Request) throws -> EventLoopFuture<[Resource]>

    func connectTaskToResource(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func disconnectTaskFromResource(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func resourcesForTask(on req: Request) throws -> EventLoopFuture<[Resource]>

    func deleteResource(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    
    func evaluateResourcesInSolutions(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension Resource: ModelParameterRepresentable {}
extension Resource: Content {}

extension ResourceAPIController {
    
    public func boot(routes: RoutesBuilder) throws {
        
        // /resources
        let resources = routes.grouped("resources")
        
        // /resources/:id
        let resourceInstance = resources.grouped(Resource.parameter)
        
        // /subtopics/:id/resources
        let subtopicConnection = routes.grouped("subtopics", Subtopic.parameter, "resources")
        
        // /tasks/:id/resources
        let taskConnection = routes.grouped("tasks", GenericTask.parameter, "resources")
        
        resources.post("video", use: createVideo(on:))
        resources.post("book", use: createBook(on:))
        resources.post("article", use: createArticle(on:))
        resources.post("evaluate-solutions", Subject.parameter, use: evaluateResourcesInSolutions(on:))
        
        resourceInstance.delete(use: deleteResource(on:))
        
        subtopicConnection.get(use: resourcesForSubtopic(on: ))
        subtopicConnection.post(Resource.parameter, use: connectTaskToResource(on: ))
        subtopicConnection.delete(Resource.parameter, use: disconnectTaskFromResource(on:))
        
        taskConnection.get(use: resourcesForTask(on:))
        taskConnection.post(Resource.parameter, use: connectTaskToResource(on:))
        taskConnection.delete(Resource.parameter, use: disconnectTaskFromResource(on:))
    }
}
