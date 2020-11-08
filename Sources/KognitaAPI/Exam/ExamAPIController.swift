//
//  ExamAPIController.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 05/11/2020.
//

import Vapor
import KognitaModels

extension Exam: ModelParameterRepresentable {}
extension Exam: Content {}
extension ExamSession: Content {}

public protocol ExamAPIController: RouteCollection, CreateModelAPIController, UpdateModelAPIController, DeleteModelAPIController {
    func create(on req: Request) -> EventLoopFuture<Exam>
    func update(on req: Request) -> EventLoopFuture<Exam>
    func delete(on req: Request) -> EventLoopFuture<HTTPStatus>
    func startExam(on req: Request) -> EventLoopFuture<ExamSession>
    func allExamsInSubject(on req: Request) -> EventLoopFuture<[Exam]>
}

extension ExamAPIController {
    public func boot(routes: RoutesBuilder) throws {
        let exams = routes.grouped("exams")

        register(create: self.create(on:), router: exams)
        register(update: self.update(on:), router: exams, parameter: Exam.self)
        register(delete: exams, parameter: Exam.self)

        exams.post(Exam.parameter, "start", use: startExam(on:))

        routes.get("subjects", Subject.parameter, "exams", use: allExamsInSubject(on:))
    }
}

struct DefaultExamAPIController: ExamAPIController {

    func create(on req: Request) -> EventLoopFuture<Exam> {
        req.repositories { repo in
            try repo.examRepository.create(from: req.content.decode())
        }
    }

    func update(on req: Request) -> EventLoopFuture<Exam> {
        req.repositories { repo in
            try repo.examRepository.update(
                id: req.parameters.get(Exam.self),
                to: req.content.decode()
            )
        }
    }

    func delete(on req: Request) -> EventLoopFuture<HTTPStatus> {
        req.repositories { repo in
            try repo.examRepository.delete(id: req.parameters.get(Exam.self))
        }
        .transform(to: .ok)
    }

    func startExam(on req: Request) -> EventLoopFuture<ExamSession> {
        req.repositories { repo in
            try repo.examSessionRepository.create(
                for: req.parameters.get(Exam.self),
                by: req.auth.require()
            )
        }
    }

    func allExamsInSubject(on req: Request) -> EventLoopFuture<[Exam]> {
        req.repositories { repo in
            try repo.examRepository.allExamsWith(
                subjectID: req.parameters.get(Subject.self)
            )
        }
    }
}
