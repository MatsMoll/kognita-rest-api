//
//  SubjectController.swift
//  App
//
//  Created by Mats Mollestad on 06/10/2018.
//

import Vapor
import KognitaCore

public final class SubjectAPIController<Repository: SubjectRepositoring>: SubjectAPIControlling {

    public static func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(Subject.self)
            .flatMap { subject in

                try Topic.DatabaseRepository
                    .getTopicsWithTaskCount(in: subject, conn: req)
                    .flatMap { topics in

                        try TaskResult.DatabaseRepository
                            .getUserLevel(for: user.requireID(), in: topics.map { try $0.topic.requireID() }, on: req)
                            .map { levels in

                                Subject.Details(
                                    subject: subject,
                                    topics: topics,
                                    levels: levels
                                )
                        }
                }
        }
    }

    public static func export(on req: Request) throws -> Future<SubjectExportContent> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Subject.self).flatMap { subject in
            try Topic.DatabaseRepository
                .exportTopics(in: subject, on: req)
        }
    }

    public static func exportAll(on req: Request) throws -> Future<[SubjectExportContent]> {
        _ = try req.requireAuthenticated(User.self)
        return try Repository
            .all(on: req)
            .flatMap { subjects in
                try subjects.map { try Topic.DatabaseRepository
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
                Subject.DatabaseRepository
                    .importContent($0, on: req)
        }
    }
}

extension Subject {
    public typealias DefaultAPIController = SubjectAPIController<Subject.DatabaseRepository>
}
