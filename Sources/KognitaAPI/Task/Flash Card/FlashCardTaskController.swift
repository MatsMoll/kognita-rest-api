//
//  FlashCardTaskController.swift
//  App
//
//  Created by Mats Mollestad on 31/03/2019.
//

import Vapor
import KognitaCore

public struct FlashCardTaskAPIController: FlashCardTaskAPIControlling {

    let conn: DatabaseConnectable

    public var repository: some FlashCardTaskRepository { FlashCardTask.DatabaseRepository(conn: conn) }
}

extension FlashCardTask {
    public typealias DefaultAPIController = FlashCardTaskAPIController
}
