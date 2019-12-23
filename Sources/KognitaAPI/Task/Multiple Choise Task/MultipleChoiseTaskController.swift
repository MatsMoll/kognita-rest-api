//
//  MultipleChoiseTaskController.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/11/2018.
//

import KognitaCore

public final class MultipleChoiseTaskAPIController
    <Repository: MultipleChoiseTaskRepository>:
    MultipleChoiseTaskAPIControlling
{}

extension MultipleChoiseTask {
    public typealias DefaultAPIController = MultipleChoiseTaskAPIController<MultipleChoiseTask.DatabaseRepository>
}
