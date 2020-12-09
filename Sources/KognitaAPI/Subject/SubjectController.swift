//
//  SubjectController.swift
//  App
//
//  Created by Mats Mollestad on 06/10/2018.
//

import Vapor
import KognitaCore
import QTIKit

extension URLQueryContainer {
    func decode<T: Decodable>() throws -> T { try decode(T.self) }
}

extension ContentContainer {
    func decode<T: Decodable>() throws -> T { try decode(T.self) }
}

public struct SubjectAPIController: SubjectAPIControlling {

    public func activeSubjects(on req: Request) throws -> EventLoopFuture<[Subject]> {

        let user = try req.auth.require(User.self)

        return req.repositories { repo in
            repo.subjectRepository.allActive(for: user.id)
        }
    }

    public func overview(on req: Request) throws -> EventLoopFuture<Subject.Overview> {
        let subjectID = try req.parameters.get(Subject.self)
        return req.repositories { repositories in
            repositories.subjectRepository
                .overviewFor(id: subjectID)
        }
    }

    public func create(on req: Request) throws -> EventLoopFuture<Subject> {
        req.repositories { repositories in
            try repositories.subjectRepository.create(from: req.content.decode(), by: req.auth.require())
        }
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subject.Update.Response> {
        req.repositories { repositories in
            try repositories.subjectRepository.updateModelWith(
                id: req.parameters.get(Subject.self),
                to: req.content.decode(),
                by: req.auth.require()
            )
        }
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        req.repositories { repositories in
            try repositories.subjectRepository.deleteModelWith(
                id: req.parameters.get(Subject.self),
                by: req.auth.require()
            )
            .transform(to: .ok)
        }
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subject> {
        req.repositories { repositories in
            try repositories.subjectRepository.find(
                req.parameters.get(Subject.self),
                or: Abort(.badRequest)
            )
        }
    }

    public func retriveAll(_ req: Request) throws -> EventLoopFuture<[Subject]> {
        req.repositories { repositories in
            try repositories.subjectRepository.all()
        }
    }

    public func testStats(on req: Request) throws -> EventLoopFuture<[SubjectTest.DetailedResult]> {

        let user = try req.auth.require(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }

        return req.repositories { repositories in
            try repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { try repositories.subjectTestRepository.stats(for: $0) }
        }
    }

    public func compendium(on req: Request) throws -> EventLoopFuture<Subject.Compendium> {
        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.subjectRepository.compendium(
                for: req.parameters.get(Subject.self),
                filter: req.query.decode(),
                for: user.id
            )
        }
    }

    public func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }

        return req.repositories { repositories in
            try repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { subject in
                    try repositories.subjectRepository.importContent(
                        in: subject,
                        peerWise: req.content.decode(),
                        user: user
                    )
            }
            .transform(to: .ok)
        }
    }

    public func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.subjectRepository
                .find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { subject in

                    try repositories.subjectTestRepository
                        .currentlyOpenTest(in: subject, user: user)
                        .failableFlatMap { currentTest in

                            try repositories.topicRepository
                                .getTopicsWithTaskCount(withSubjectID: subject.id)
                                .flatMap { topics in

                                    repositories.taskResultRepository
                                        .getUserLevel(for: user.id, in: topics.map { $0.topic.id })
                                        .flatMap { userLevels in

                                            repositories.examRepository
                                                .allExamsWithNumberOfTasksFor(subjectID: subject.id, userID: user.id)
                                                .failableFlatMap { exams in

                                                    try repositories.subjectRepository
                                                        .active(subject: subject, for: user)
                                                        .failableFlatMap { activeSubject in

                                                            var canPractice = activeSubject?.canPractice ?? false
                                                            if user.isAdmin {
                                                                canPractice = true
                                                            }

                                                            return repositories.userRepository
                                                                .isModerator(user: user, subjectID: subject.id)
                                                                .flatMapThrowing { isModerator in

                                                                    Subject.Details(
                                                                        subject: subject,
                                                                        topics: topics.map { topic in
                                                                            var level = topic.userLevelZero()
                                                                            if let unwrapedLevel = userLevels.first(where: { $0.topicID == topic.topic.id }) {
                                                                                level = unwrapedLevel
                                                                            }
                                                                            return Topic.UserOverview(
                                                                                id: topic.topic.id,
                                                                                name: topic.topic.name,
                                                                                typingTaskCount: topic.typingTaskCount,
                                                                                multipleChoiceTaskCount: topic.multipleChoiceTaskCount,
                                                                                userLevel: level
                                                                            )
                                                                        },
                                                                        openTest: currentTest,
                                                                        numberOfTasks: 0,
                                                                        isActive: activeSubject?.subjectID == subject.id,
                                                                        canPractice: canPractice,
                                                                        isModerator: isModerator,
                                                                        exams: exams
                                                                    )
                                                            }
                                                    }
                                            }
                                    }
                            }
                    }
            }
        }
    }

    public func export(on req: Request) throws -> EventLoopFuture<Subject.Export> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.notFound) }

        return req.repositories { repositories in
            return try repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { try repositories.topicRepository.exportTopics(in: $0) }
        }
    }

    public func exportAll(on req: Request) throws -> EventLoopFuture<[Subject.Export]> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.notFound) }

        return req.repositories { repositories in
            try repositories.subjectRepository.all()
                .failableFlatMap { subjects in
                    try subjects.map {
                        try repositories.topicRepository
                            .exportTopics(in: $0)
                    }
                    .flatten(on: req.eventLoop)
            }
        }
    }

    public func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else { throw Abort(.forbidden) }

        return req.repositories { repositories in
            try req.content
                .decode([Subject.Import].self)
                .map { repositories.subjectRepository.importContent($0) }
                .flatten(on: req.eventLoop)
                .transform(to: .ok)
        }
    }

    public func getListContent(_ req: Request) throws -> EventLoopFuture<Dashboard> {
        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            repositories.subjectRepository
                .allSubjects(for: user, searchQuery: .init())
                .flatMap { subjects in

                    repositories.taskResultRepository
                        .recommendedRecap(for: user.id, upperBoundDays: 10, lowerBoundDays: -5, limit: 1)
                        .failableFlatMap { recommendedRecaps in

                            try repositories.subjectTestRepository
                                .currentlyOpenTest(for: user)
                                .map { test in

                                    // FIXME: - Set ongoing sessions parameters
                                    Dashboard(
                                        subjects: subjects,
                                        ongoingPracticeSession: nil,
                                        ongoingTestSession: nil,
                                        openedTest: test,
                                        recommendedRecap: recommendedRecaps.first
                                    )
                            }
                        }
            }
        }
    }

    public func makeSubject(inactive req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { subject in

                    try repositories.subjectRepository.mark(inactive: subject, for: user)
            }
            .transform(to: .ok)
        }
    }

    public func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.subjectRepository.find(req.parameters.get(Subject.self), or: Abort(.badRequest))
                .failableFlatMap { subject in

                    try repositories.subjectRepository.mark(active: subject, canPractice: true, for: user)
            }
            .transform(to: .ok)
        }
    }

    public func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            try repositories.subjectRepository.grantModeratorPrivilege(
                for: req.content.decode(Subject.ModeratorPrivilegeRequest.self).userID,
                in: req.parameters.get(Subject.self),
                by: user
            )
            .transform(to: .ok)
        }
    }

    public func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)

        return req.repositories { repositories in
            return try repositories.subjectRepository.revokeModeratorPrivilege(
                for: req.content.decode(Subject.ModeratorPrivilegeRequest.self).userID,
                in: req.parameters.get(Subject.self),
                by: user
            )
            .transform(to: .ok)
        }
    }

    public func importTopic(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.auth.require(User.self)
        let subjectID = try req.parameters.get(Subject.self)
        let content = try req.content.decode(Topic.Import.self)

        return req.repositories { repo in
            repo.userRepository
                .isModerator(user: user, subjectID: subjectID)
                .ifFalse(throw: Abort(.forbidden))
                .failableFlatMap {
                    repo.topicRepository.importContent(
                        from: content,
                        in: subjectID
                    )
                }
                .transform(to: .ok)
        }
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
