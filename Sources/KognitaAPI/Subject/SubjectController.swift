//
//  SubjectController.swift
//  App
//
//  Created by Mats Mollestad on 06/10/2018.
//

import Vapor
import KognitaCore

extension QueryContainer {
    func decode<T: Decodable>() throws -> T { try decode(T.self) }
}

public struct SubjectAPIController: SubjectAPIControlling {

    let repositories: RepositoriesRepresentable

    var subjectRepository: SubjectRepositoring { repositories.subjectRepository }
    var testReposistory: SubjectTestRepositoring { repositories.subjectTestRepository }
    var topicRepository: TopicRepository { repositories.topicRepository }
    var taskResultRepository: TaskResultRepositoring.Type { TaskResult.DatabaseRepository.self }
    var userRepository: UserRepository { repositories.userRepository }

    public func create(on req: Request) throws -> EventLoopFuture<Subject> {
        try req.create(in: subjectRepository.create(from: by: ))
    }

    public func update(on req: Request) throws -> EventLoopFuture<Subject.Update.Response> {
        try req.update(with: subjectRepository.updateModelWith(id: to: by: ), parameter: Subject.self)
    }

    public func delete(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.delete(with: subjectRepository.deleteModelWith(id: by: ), parameter: Subject.self)
    }

    public func retrive(on req: Request) throws -> EventLoopFuture<Subject> {
        try req.retrive(with: subjectRepository.find, parameter: Subject.self)
    }

    public func retriveAll(_ req: Request) throws -> EventLoopFuture<[Subject]> {
        try subjectRepository.all()
    }

    public func testStats(on req: Request) throws -> EventLoopFuture<[SubjectTest.DetailedResult]> {

        let user = try req.requireAuthenticated(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap(self.testReposistory.stats)
    }

    public func compendium(on req: Request) throws -> EventLoopFuture<Subject.Compendium> {
        _ = try req.requireAuthenticated(User.self)

        return try subjectRepository.compendium(
            for: req.parameters.modelID(Subject.self),
            filter: req.query.decode()
        )
    }

    public func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        guard user.isAdmin else { throw Abort(.notFound) }


        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .and(req.content.decode([Task.PeerWise].self))
            .flatMap { (subject, tasks) in
                try self.subjectRepository.importContent(
                    in: subject,
                    peerWise: tasks,
                    user: user
                )
        }
        .transform(to: .ok)
    }

    public func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details> {

        let user = try req.requireAuthenticated(User.self)

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap { subject in

                try self.testReposistory
                    .currentlyOpenTest(in: subject, user: user)
                    .flatMap { test in

                        try self.topicRepository
                            .getTopicsWithTaskCount(in: subject)
                            .flatMap { topics in

                                try self.taskResultRepository
                                    .getUserLevel(for: user.id, in: topics.map { $0.topic.id }, on: req)
                                    .flatMap { levels in

                                        try self.subjectRepository.active(subject: subject, for: user)
                                            .flatMap { activeSubject in

                                                var canPractice = activeSubject?.canPractice ?? false
                                                if user.isAdmin {
                                                    canPractice = true
                                                }

                                                return try self.userRepository
                                                    .isModerator(user: user, subjectID: subject.id)
                                                    .map { true }
                                                    .catchMap { _ in false }
                                                    .map { isModerator in
                                                        throw Abort(.notImplemented)
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
        let user = try req.requireAuthenticated(User.self)
        guard user.isAdmin else { throw Abort(.notFound) }

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap(topicRepository.exportTopics(in:))
    }

    public func exportAll(on req: Request) throws -> EventLoopFuture<[SubjectExportContent]> {
        _ = try req.requireAuthenticated(User.self)

        return try subjectRepository.all()
            .flatMap { subjects in
                try subjects.map { try self.topicRepository
                    .exportTopics(in: $0)
                }
                .flatten(on: req)
        }
    }

    public func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)

        guard user.isAdmin else {
            throw Abort(.forbidden)
        }
        return try req.content
            .decode([SubjectExportContent].self)
            .flatMap { content in
                content.map {
                    self.subjectRepository.importContent($0)
                }
                .flatten(on: req)
                .transform(to: .ok)
        }
    }

    public func getListContent(_ req: Request) throws -> EventLoopFuture<Dashboard> {
        let user = try req.requireAuthenticated(User.self)

        return try subjectRepository
            .allSubjects(for: user)
            .flatMap { subjects in

                try self.testReposistory
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

        let user = try req.requireAuthenticated(User.self)

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap { subject in

                try self.subjectRepository.mark(inactive: subject, for: user)
        }
        .transform(to: .ok)
    }

    public func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try subjectRepository.find(req.parameters.modelID(Subject.self), or: Abort(.badRequest))
            .flatMap { subject in

                try self.subjectRepository.mark(active: subject, canPractice: true, for: user)
        }
        .transform(to: .ok)
    }

    public func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(Subject.ModeratorPrivilegeRequest.self)
            .flatMap { content in

                try self.subjectRepository.grantModeratorPrivilege(
                    for: content.userID,
                    in: req.parameters.modelID(Subject.self),
                    by: user
                )
        }
        .transform(to: .ok)
    }

    public func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus> {

        let user = try req.requireAuthenticated(User.self)

        return try req.content
            .decode(Subject.ModeratorPrivilegeRequest.self)
            .flatMap { content in

                try self.subjectRepository.revokeModeratorPrivilege(
                    for: content.userID,
                    in: req.parameters.modelID(Subject.self),
                    by: user
                )
        }
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
