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
        try req.create(in: req.repositories.topicRepository.create(from:  by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Topic> {
        try req.update(with: req.repositories.topicRepository.updateModelWith(id: to: by: ), parameter: Topic.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.topicRepository.deleteModelWith(id: by: ), parameter: Topic.self)
    }

    public func retrive(_ req: Request) throws -> EventLoopFuture<Topic> {
        try req.retrive(with: req.repositories.topicRepository.find(_: or:), parameter: Topic.self)
    }

    public func retriveAll(_ req: Request) throws -> EventLoopFuture<[Topic]> {
        try req.repositories.topicRepository.all()
    }

    public func getAllIn(subject req: Request) throws -> EventLoopFuture<[Topic]> {
        try req.repositories.topicRepository.getTopicsWith(subjectID: req.parameters.get(Subject.self))
    }

    public func save(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        try req.repositories.topicRepository.save(
            topics: req.content.decode(),
            forSubjectID: req.parameters.get(Subject.self),
            user: req.auth.require()
        )
        .transform(to: .ok)
    }
}

extension Topic {
    public typealias DefaultAPIController = TopicAPIController
}
