//
//  FlashCardTaskController.swift
//  App
//
//  Created by Mats Mollestad on 31/03/2019.
//

import Vapor
import KognitaCore

extension TypingTask: ModelParameterRepresentable {}

public struct FlashCardTaskAPIController: FlashCardTaskAPIControlling {

    let repositories: RepositoriesRepresentable

    public var repository: FlashCardTaskRepository { repositories.typingTaskRepository }

    public func create(on req: Request) throws -> EventLoopFuture<Task> {
        try req.create(in: repository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Task> {
        try req.update(with: repository.updateModelWith(id: to: by: ), parameter: TypingTask.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: repository.deleteModelWith(id: by: ), parameter: TypingTask.self)
    }
}

extension FlashCardTask {
    public typealias DefaultAPIController = FlashCardTaskAPIController
}
