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
                            .flatMap { levels in

                                try Repository.active(subject: subject, for: user, on: req)
                                    .map { activeSubject in

                                        var canPractice = activeSubject?.canPractice ?? false
                                        if user.isAdmin {
                                            canPractice = true
                                        }

                                        return Subject.Details(
                                            subject: subject,
                                            topics: topics,
                                            levels: levels,
                                            isActive: activeSubject != nil,
                                            canPractice: canPractice
                                        )
                                }
                        }
                }
        }
    }

    public static func export(on req: Request) throws -> EventLoopFuture<SubjectExportContent> {
        _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Subject.self).flatMap { subject in
            try Topic.DatabaseRepository
                .exportTopics(in: subject, on: req)
        }
    }

    public static func exportAll(on req: Request) throws -> EventLoopFuture<[SubjectExportContent]> {
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

    public static func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)

        guard user.isAdmin else {
            throw Abort(.forbidden)
        }
        return try req.content
            .decode([SubjectExportContent].self)
            .flatMap { content in
                content.map {
                    Subject.DatabaseRepository
                        .importContent($0, on: req)
                }
                .flatten(on: req)
                .transform(to: .ok)
        }
    }

    public static func getListContent(_ req: Request) throws -> EventLoopFuture<Subject.ListContent> {
        let user = try req.requireAuthenticated(User.self)

        return try Repository.all(on: req)
            .flatMap { subjects in

                try SubjectTest.DatabaseRepository
                    .currentlyOpenTest(for: user, on: req)
                    .map { test in

                        // FIXME: - Set ongoing sessions parameters
                        Subject.ListContent(
                            subjects: subjects,
                            ongoingPracticeSession: nil,
                            ongoingTestSession: nil,
                            openedTest: subjects
                                .first(where: { $0.id == test?.subjectID })
                                .flatMap {
                                    test?.response(with: $0)
                            }
                        )
                }
        }
    }

    public static func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.parameters
            .next(Subject.self)
            .flatMap { subject in

                try Repository.mark(active: subject, canPractice: true, for: user, on: req)
        }
        .transform(to: .ok)
    }
}

extension Subject {
    public typealias DefaultAPIController = SubjectAPIController<Subject.DatabaseRepository>
}
