//
//  MultipleChoiseTaskController.swift
//  AppTests
//
//  Created by Mats Mollestad on 11/11/2018.
//

import Vapor
import FluentPostgreSQL
import KognitaCore


final class MultipleChoiseTaskController: KognitaCRUDControllable, RouteCollection {
    
    typealias Model = MultipleChoiseTask
    typealias Response = MultipleChoiseTask.Data

    static let shared = MultipleChoiseTaskController()

    var parameter: PathComponentsRepresentable { return MultipleChoiseTask.parameter }

    func boot(router: Router) {
        router.register(controller: self, at: "tasks/multiple-choise")
    }
    
    static func map(model: MultipleChoiseTask, on conn: DatabaseConnectable) throws -> EventLoopFuture<MultipleChoiseTask.Data> {
        
        return try MultipleChoiseTask.Repository
            .get(task: model, conn: conn)
    }
    
    static func mapCreate(response: MultipleChoiseTask, on conn: DatabaseConnectable) throws -> EventLoopFuture<MultipleChoiseTask.Data> {
        
        return try MultipleChoiseTask.Repository
            .get(task: response, conn: conn)
    }
    
    static func getAll(_ req: Request) throws -> EventLoopFuture<[MultipleChoiseTask.Data]> {
        return MultipleChoiseTask.Repository
            .all(on: req)
            .flatMap { tasks in
                
                try tasks.map {
                    try MultipleChoiseTask.Repository
                        .get(task: $0, conn: req)
                }.flatten(on: req)
        }
    }
}

