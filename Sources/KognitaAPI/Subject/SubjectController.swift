//
//  SubjectController.swift
//  App
//
//  Created by Mats Mollestad on 06/10/2018.
//

import Vapor
import KognitaCore

public final class SubjectController: KognitaCRUDControllable, RouteCollection {

    typealias Model = Subject
    typealias ResponseContent = Subject

    public func boot(router: Router) {
        router.register(controller: self, at: "subjects")
        router.get("subjects", Subject.parameter, "export", use: SubjectController.export)
        router.get("subjects/export", use: SubjectController.exportAll)
        router.post("subjects/import", use: SubjectController.importContent)
    }
    
    public static func getAll(_ req: Request) throws -> EventLoopFuture<[Subject]> {
        return Subject.Repository
            .all(on: req)
    }

    public static func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(Subject.self)
            .flatMap { subject in

                try Topic.Repository
                    .getTopicsWithTaskCount(in: subject, conn: req)
                    .flatMap { topics in

                        try TaskResultRepository
                            .getUserLevel(for: user.requireID(), in: topics.map { try $0.topic.requireID() }, on: req)
                            .map { levels in

                                try Subject.Details(
                                    subject: subject,
                                    topics: topics,
                                    levels: levels
                                )
                        }
                }
        }
    }

//    func createTest(_ req: Request) throws -> Future<SubjectTestSet> {
//
//        let user = try req.requireAuthenticated(User.self)
//
//        return try req.parameters.next(Subject.self)
//            .and(req.content.decode(CreateSubjectTest.self))
//            .flatMap { (subject, _) in
//                try SubjectTest.create(for: user, on: subject, with: req)
//            }
//    }

    public static func export(on req: Request) throws -> Future<SubjectExportContent> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Subject.self).flatMap { subject in
            try Topic.Repository
                .exportTopics(in: subject, on: req)
        }
    }

    public static func exportAll(on req: Request) throws -> Future<[SubjectExportContent]> {
        _ = try req.requireAuthenticated(User.self)
        return Subject.Repository
            .all(on: req)
            .flatMap { subjects in
                try subjects.map { try Topic.Repository
                    .exportTopics(in: $0, on: req)
                }
                .flatten(on: req)
        }
    }

    public static func importContent(on req: Request) throws -> Future<Subject> {
        _ = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(SubjectExportContent.self)
            .flatMap {
                Subject.Repository
                    .importContent($0, on: req)
        }
    }
}

