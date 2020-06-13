//
//  MultipleChoiseTaskController.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/11/2018.
//

import KognitaCore
import FluentPostgreSQL

public struct MultipleChoiceTaskAPIController: MultipleChoiseTaskAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some MultipleChoiseTaskRepository { MultipleChoiceTask.DatabaseRepository(conn: conn) }
}

extension MultipleChoiceTask {
    public typealias DefaultAPIController = MultipleChoiceTaskAPIController
}
