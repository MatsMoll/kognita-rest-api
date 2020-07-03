//
//  SubjectController.swift
//  App
//
//  Created by Mats Mollestad on 06/10/2018.
//

import Vapor
import KognitaCore

extension URLQueryContainer {
    func decode<T: Decodable>() throws -> T { try decode(T.self) }
}

extension ContentContainer {
    func decode<T: Decodable>() throws -> T { try decode(T.self) }
}

public struct SubjectAPIController: SubjectAPIControlling {

    public func overview(on req: Request) throws -> EventLoopFuture<Subject.Overview> {
        throw Abort(.notImplemented)
    }

    public func create(on req: Request) throws -> EventLoopFuture<Subject> {
        try req.create(in: req.repositories.subjectRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subject.Update.Response> {
        try req.update(with: req.repositories.subjectRepository.updateModelWith(id: to: by: ), parameter: Subject.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: req.repositories.subjectRepository.deleteModelWith(id: by: ), parameter: Subject.self)
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subject> {
        try req.retrive(with: req.repositories.subjectRepository.find, parameter: Subject.self)
    }

    public func retriveAll(_ req: Request) throws -> EventLoopFuture<[Subject]> {
        try req.repositories.subjectRepository.all()
    }

    public func testStats(on req: Request) throws -> EventLoopFuture<[SubjectTest.DetailedResult]> {

        let user = try req.auth.require(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap(event: req.repositories.subjectTestRepository.stats)
    }

    public func compendium(on req: Request) throws -> EventLoopFuture<Subject.Compendium> {
        _ = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.compendium(
            for: req.parameters.get(Subject.self),
            filter: req.query.decode()
        )
    }

    public func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap { subject in
                try req.repositories.subjectRepository.importContent(
                    in: subject,
                    peerWise: req.content.decode(),
                    user: user
                )
        }
        .transform(to: .ok)
    }

    public func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap { subject in

                try req.repositories.subjectTestRepository
                    .currentlyOpenTest(in: subject, user: user)
                    .failableFlatMap { currentTest in

                        try req.repositories.topicRepository
                            .getTopicsWithTaskCount(in: subject)
                            .flatMap { topics in

                                req.repositories.taskResultRepository
                                    .getUserLevel(for: user.id, in: topics.map { $0.topic.id })
                                    .failableFlatMap { userLevels in

                                        try req.repositories.subjectRepository.active(subject: subject, for: user)
                                            .failableFlatMap { activeSubject in

                                                var canPractice = activeSubject?.canPractice ?? false
                                                if user.isAdmin {
                                                    canPractice = true
                                                }

                                                return req.repositories.userRepository
                                                    .isModerator(user: user, subjectID: subject.id)
                                                    .flatMapThrowing { isModerator in

                                                        Subject.Details(
                                                            subject: subject,
                                                            topics: topics.compactMap { topic in
                                                                guard let level = userLevels.first(where: { $0.topicID == topic.topic.id }) else { return nil }
                                                                return Topic.UserOverview(
                                                                    id: topic.topic.id,
                                                                    name: topic.topic.name,
                                                                    numberOfTasks: topic.taskCount,
                                                                    userLevel: level
                                                                )
                                                            },
                                                            subjectLevel: Subject.UserLevel.init(subjectID: subject.id, correctScore: 0, maxScore: 0),
                                                            openTest: currentTest,
                                                            numberOfTasks: 0,
                                                            isActive: activeSubject?.subjectID == subject.id,
                                                            canPractice: canPractice,
                                                            isModerator: isModerator
                                                        )
//                                                        Subject.Details(
//                                                            subject: subject,
//                                                            topics: topics,
//                                                            levels: levels,
//                                                            isActive: activeSubject != nil,
//                                                            canPractice: canPractice,
//                                                            isModerator: isModerator,
//                                                            openTest: test
//                                                        )
                                                }
                                        }
                                }
                        }
                }
        }
    }

    public func export(on req: Request) throws -> EventLoopFuture<SubjectExportContent> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.notFound) }

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap(event: req.repositories.topicRepository.exportTopics(in:))
    }

    public func exportAll(on req: Request) throws -> EventLoopFuture<[SubjectExportContent]> {
        _ = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.all()
            .failableFlatMap { subjects in
                try subjects.map { try req.repositories.topicRepository
                    .exportTopics(in: $0)
                }
                .flatten(on: req.eventLoop)
        }
    }

    public func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)

        guard user.isAdmin else {
            throw Abort(.forbidden)
        }
        return try req.content
            .decode([SubjectExportContent].self)
            .map { req.repositories.subjectRepository.importContent($0) }
            .flatten(on: req.eventLoop)
            .transform(to: .ok)
    }

    public func getListContent(_ req: Request) throws -> EventLoopFuture<Dashboard> {
        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository
            .allSubjects(for: user)
            .failableFlatMap { subjects in

                try req.repositories.subjectTestRepository
                    .currentlyOpenTest(for: user)
                    .map { test in

                        // FIXME: - Set ongoing sessions parameters
                        Dashboard(
                            subjects: subjects,
                            ongoingPracticeSession: nil,
                            ongoingTestSession: nil,
                            openedTest: test
                        )
                }
        }
    }

    public func makeSubject(inactive req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap { subject in

                try req.repositories.subjectRepository.mark(inactive: subject, for: user)
        }
        .transform(to: .ok)
    }

    public func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
            .failableFlatMap { subject in

                try req.repositories.subjectRepository.mark(active: subject, canPractice: true, for: user)
        }
        .transform(to: .ok)
    }

    public func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.grantModeratorPrivilege(
            for: req.content.decode(Subject.ModeratorPrivilegeRequest.self).userID,
            in: req.parameters.get(Subject.self),
            by: user
        )
        .transform(to: .ok)
    }

    public func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return try req.repositories.subjectRepository.revokeModeratorPrivilege(
            for: req.content.decode(Subject.ModeratorPrivilegeRequest.self).userID,
            in: req.parameters.get(Subject.self),
            by: user
        )
        .transform(to: .ok)
    }
}

extension Subject {
    public typealias DefaultAPIController = SubjectAPIController
}

extension Subject {
    struct ModeratorPrivilegeRequest: Codable {
        let userID: User.ID
    }
}
