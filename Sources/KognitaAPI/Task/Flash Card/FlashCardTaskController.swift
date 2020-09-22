//
//  FlashCardTaskController.swift
//  App
//
//  Created by Mats Mollestad on 31/03/2019.
//

import Vapor
import KognitaCore

extension TypingTask: ModelParameterRepresentable, Content {}

public struct FlashCardTaskAPIController: FlashCardTaskAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<TypingTask> {
        try req.create(in: req.repositories.typingTaskRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<TypingTask> {
        try req.update(with: req.repositories.typingTaskRepository.updateModelWith(id: to: by: ), parameter: TypingTask.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.typingTaskRepository.deleteModelWith(id: by: ), parameter: TypingTask.self)
    }

    public func forceDelete(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        try req.repositories.typingTaskRepository.forceDelete(taskID: req.parameters.get(TypingTask.self), by: req.auth.require())
            .transform(to: .ok)
    }
}

extension TypingTask {
    public typealias DefaultAPIController = FlashCardTaskAPIController
}
