//
//  FlashCardTaskController.swift
//  App
//
//  Created by Mats Mollestad on 31/03/2019.
//

import Vapor
import KognitaCore

public final class FlashCardTaskAPIController
    <Repository: FlashCardTaskRepository>:
    FlashCardTaskAPIControlling {}

extension FlashCardTask {
    public typealias DefaultAPIController = FlashCardTaskAPIController<FlashCardTask.DatabaseRepository>
}
