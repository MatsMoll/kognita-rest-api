//
//  DefaultResourceAPIController.swift
//  
//
//  Created by Mats Mollestad on 06/01/2021.
//

import Foundation
import Vapor
import KognitaModels

struct DefaultResourceAPIController: ResourceAPIController {
    
    func createVideo(on req: Request) throws -> EventLoopFuture<Resource.ID> {
        let user = try req.auth.require(User.self)
        let video = try req.content.decode(VideoResource.Create.Data.self)
        return req.repositories { repo in
            repo.resourceRepository.create(video: video, by: user.id)
        }
    }
    
    func createBook(on req: Request) throws -> EventLoopFuture<Resource.ID> {
        let user = try req.auth.require(User.self)
        let book = try req.content.decode(BookResource.Create.Data.self)
        return req.repositories { repo in
            repo.resourceRepository.create(book: book, by: user.id)
        }
    }
    
    func createArticle(on req: Request) throws -> EventLoopFuture<Resource.ID> {
        let user = try req.auth.require(User.self)
        let article = try req.content.decode(ArticleResource.Create.Data.self)
        return req.repositories { repo in
            repo.resourceRepository.create(article: article, by: user.id)
        }
    }
    
    func connectSubtopicToResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let subtopicID = try req.parameters.get(Subtopic.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.connect(subtopicID: subtopicID, to: resourceID)
        }
        .transform(to: .created)
    }
    
    func disconnectSubtopicFromResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let subtopicID = try req.parameters.get(Subtopic.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.disconnect(subtopicID: subtopicID, from: resourceID)
        }
        .transform(to: .ok)
    }
    
    func resourcesForSubtopic(on req: Request) throws -> EventLoopFuture<[Resource]> {
        let subtopicID = try req.parameters.get(Subtopic.self)
        return req.repositories { repo in
            repo.resourceRepository.resourcesFor(subtopicID: subtopicID)
        }
    }
    
    func connectTaskToResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let taskID = try req.parameters.get(GenericTask.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.connect(taskID: taskID, to: resourceID)
        }
        .transform(to: .created)
    }
    
    func disconnectTaskFromResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let taskID = try req.parameters.get(GenericTask.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.disconnect(taskID: taskID, from: resourceID)
        }
        .transform(to: .ok)
    }
    
    func resourcesForTask(on req: Request) throws -> EventLoopFuture<[Resource]> {
        let taskID = try req.parameters.get(GenericTask.self)
        return req.repositories { repo in
            repo.resourceRepository.resourcesFor(taskID: taskID)
        }
    }
    
    func deleteResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.deleteResourceWith(id: resourceID)
        }
        .transform(to: .ok)
    }
    
    func evaluateResourcesInSolutions(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.forbidden) }
        let subjectID = try req.parameters.get(Subject.self)
        
        return req.repositories { repo in
            repo.resourceRepository.analyseResourcesIn(subjectID: subjectID)
        }
        .transform(to: .ok)
    }
    
    func connectTermToResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let termID = try req.parameters.get(Term.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.connect(termID: termID, to: resourceID)
        }
        .transform(to: .created)
    }
    
    func disconnectTermFromResource(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let termID = try req.parameters.get(Term.self)
        let resourceID = try req.parameters.get(Resource.self)
        return req.repositories { repo in
            repo.resourceRepository.disconnect(termID: termID, from: resourceID)
        }
        .transform(to: .ok)
    }
}
