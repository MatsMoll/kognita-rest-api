//
//  TopicController.swift
//  App
//
//  Created by Mats Mollestad on 07/10/2018.
//

import Vapor
import KognitaCore

public struct TopicAPIController: TopicAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<Topic> {
        req.repositories { repositories in
            try repositories.topicRepository.create(from: req.content.decode(), by: req.auth.require())
        }
    }

    public func update(on req: Request) throws -> EventLoopFuture<Topic> {
        req.repositories { repositories in
            try repositories.topicRepository.updateModelWith(
                id: req.parameters.get(Topic.self),
                to: req.content.decode(),
                by: req.auth.require()
            )
        }
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        req.repositories { repositories in
            try repositories.topicRepository.deleteModelWith(
                id: req.parameters.get(Topic.self),
                by: req.auth.require()
            )
            .transform(to: .ok)
        }
    }

    public func retrive(_ req: Request) throws -> EventLoopFuture<Topic> {
        req.repositories { repositories in
            try repositories.topicRepository.find(
                req.parameters.get(Topic.self),
                or: Abort(.badRequest)
            )
        }
    }

    public func retriveAll(_ req: Request) throws -> EventLoopFuture<[Topic]> {
        req.repositories { repositories in
            try repositories.topicRepository.all()
        }
    }

    public func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]> {
        req.repositories { repositories in
            try repositories.topicRepository.getTopicsWith(subjectID: req.parameters.get(Subject.self))
        }
    }

    public func save(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        req.repositories { repositories in
            try repositories.topicRepository.save(
                topics: req.content.decode(),
                forSubjectID: req.parameters.get(Subject.self),
                user: req.auth.require()
            )
            .transform(to: .ok)
        }
    }

    public func export(topic req: Request) throws -> EventLoopFuture<Topic.Export> {
        let user = try req.auth.require(User.self)
        let topicID = try req.parameters.get(Topic.self)

        return req.repositories { repo in
            try repo.userRepository
                .isModerator(user: user, topicID: topicID)
                .ifFalse(throw: Abort(.forbidden))
                .flatMap {
                    repo.topicRepository.find(topicID, or: Abort(.badRequest))
                        .failableFlatMap { topic in
                            try repo.topicRepository.exportTasks(in: topic)
                    }
                }
        }
    }
    
    public func importSubtopics(req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        
        let user = try req.auth.require(User.self)
        let topicID = try req.parameters.get(Topic.self)
        let content = try req.content.decode(Subtopic.Import.self)
        
        return req.repositories { repo in
            try repo.userRepository
                .isModerator(user: user, topicID: topicID)
                .ifFalse(throw: Abort(.forbidden))
                .flatMap {
                    repo.topicRepository
                        .find(topicID, or: Abort(.badRequest, reason: "Invalid Topic ID"))
                    
                }.flatMapThrowing { topic in
                    try repo.topicRepository
                        .importContent(from: content, in: topic, resourceMap: [:])
                }
        }
        .transform(to: .ok)
    }
}

extension Topic {
    public typealias DefaultAPIController = TopicAPIController
}
