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
        try req.repositories.topicRepository.create(from: req.content.decode(), by: req.auth.require())
    }

    public func update(on req: Request) throws -> EventLoopFuture<Topic> {
        try req.repositories.topicRepository.updateModelWith(
            id: req.parameters.get(Topic.self),
            to: req.content.decode(),
            by: req.auth.require()
        )
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.repositories.topicRepository.deleteModelWith(
            id: req.parameters.get(Topic.self),
            by: req.auth.require()
        )
        .transform(to: .ok)
    }

    public func retrive(_ req: Request) throws -> EventLoopFuture<Topic> {
        try req.repositories.topicRepository.find(
            req.parameters.get(Topic.self),
            or: Abort(.badRequest)
        )
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
