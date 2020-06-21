//
//  MultipleChoiseTaskController.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/11/2018.
//

import KognitaCore
import FluentPostgreSQL
import Vapor

extension MultipleChoiceTask: ModelParameterRepresentable {}

public struct MultipleChoiceTaskAPIController: MultipleChoiseTaskAPIControlling {

    let repositories: RepositoriesRepresentable

    public var repository: MultipleChoiseTaskRepository { repositories.multipleChoiceTaskRepository }

    public func create(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask> {
        try req.create(in: repository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask> {
        try req.update(with: repository.updateModelWith(id: to: by: ), parameter: MultipleChoiceTask.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: repository.deleteModelWith(id: by: ), parameter: MultipleChoiceTask.self)
    }
}

extension MultipleChoiceTask {
    public typealias DefaultAPIController = MultipleChoiceTaskAPIController
}
