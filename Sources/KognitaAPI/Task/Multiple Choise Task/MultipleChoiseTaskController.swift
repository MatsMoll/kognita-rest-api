//
//  MultipleChoiseTaskController.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/11/2018.
//

import KognitaCore
import Vapor

extension MultipleChoiceTask: ModelParameterRepresentable {
    public static var identifier: String = "multiplechoicetask"
}

public struct MultipleChoiceTaskAPIController: MultipleChoiseTaskAPIControlling {

    public func create(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask> {
        req.repositories { repositories in
            try repositories.multipleChoiceTaskRepository.create(from: req.content.decode(), by: req.auth.require())
        }
    }

    public func update(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask> {
        req.repositories { repositories in
            try repositories.multipleChoiceTaskRepository.updateModelWith(
                id: req.parameters.get(MultipleChoiceTask.self),
                to: req.content.decode(),
                by: req.auth.require()
            )
        }
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        req.repositories { repositories in
            try repositories.multipleChoiceTaskRepository.deleteModelWith(
                id: req.parameters.get(MultipleChoiceTask.self),
                by: req.auth.require()
            )
            .transform(to: .ok)
        }
    }

    public func forceDelete(on req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        req.repositories { repositories in
            try repositories.multipleChoiceTaskRepository.forceDelete(taskID: req.parameters.get(MultipleChoiceTask.self), by: req.auth.require())
                .transform(to: .ok)
        }
    }
}

extension MultipleChoiceTask {
    public typealias DefaultAPIController = MultipleChoiceTaskAPIController
}
