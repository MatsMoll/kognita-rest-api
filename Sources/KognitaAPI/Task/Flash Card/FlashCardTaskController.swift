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
        req.repositories { repositories in
            try repositories.typingTaskRepository.create(from: req.content.decode(), by: req.auth.require())
        }
    }

    public func update(on req: Request) throws -> EventLoopFuture<TypingTask> {
        req.repositories { repositories in
            try repositories.typingTaskRepository.updateModelWith(
                id: req.parameters.get(TypingTask.self),
                to: req.content.decode(),
                by: req.auth.require()
            )
        }
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        req.repositories { repositories in
            try repositories.typingTaskRepository.deleteModelWith(
                id: req.parameters.get(TypingTask.self),
                by: req.auth.require()
            )
            .transform(to: .ok)
        }
    }

    public func forceDelete(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        req.repositories { repositories in
            try repositories.typingTaskRepository.forceDelete(taskID: req.parameters.get(TypingTask.self), by: req.auth.require())
                .transform(to: .ok)
        }
    }
}

extension TypingTask {
    public typealias DefaultAPIController = FlashCardTaskAPIController
}
