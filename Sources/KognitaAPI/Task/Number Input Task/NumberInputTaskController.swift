//
//  NumberInputTaskController.swift
//  App
//
//  Created by Mats Mollestad on 23/03/2019.
//

import Vapor
import KognitaCore

final class NumberInputTaskController: KognitaCRUDControllable, RouteCollection {
    
    static let shared = NumberInputTaskController()

    typealias Model = NumberInputTask
    typealias Response = NumberInputTask.Data
    
    var parameter: PathComponentsRepresentable { return NumberInputTask.parameter }

    func boot(router: Router) {
        router.register(controller: self, at: "tasks/input")
    }
    
    static func map(model: NumberInputTask, on conn: DatabaseConnectable) throws -> EventLoopFuture<NumberInputTask.Data> {
        return try NumberInputTask.Repository
            .get(task: model, conn: conn)
    }
    
    static func mapCreate(response: NumberInputTask, on conn: DatabaseConnectable) throws -> EventLoopFuture<NumberInputTask.Data> {
        return try NumberInputTask.Repository
            .get(task: response, conn: conn)
    }

    static func getAll(_ req: Request) throws -> EventLoopFuture<[NumberInputTask.Data]> {
        return NumberInputTask.Repository
            .all(on: req)
            .flatMap { tasks in

                return try tasks.map {
                    try NumberInputTask.Repository
                        .get(task: $0, conn: req)
                    }.flatten(on: req)
        }
    }
}
