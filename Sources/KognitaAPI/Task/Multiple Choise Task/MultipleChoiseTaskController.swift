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
        try req.create(in: req.repositories.multipleChoiceTaskRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<MultipleChoiceTask> {
        try req.update(with: req.repositories.multipleChoiceTaskRepository.updateModelWith(id: to: by: ), parameter: MultipleChoiceTask.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.multipleChoiceTaskRepository.deleteModelWith(id: by: ), parameter: MultipleChoiceTask.self)
    }
}

extension MultipleChoiceTask {
    public typealias DefaultAPIController = MultipleChoiceTaskAPIController
}
