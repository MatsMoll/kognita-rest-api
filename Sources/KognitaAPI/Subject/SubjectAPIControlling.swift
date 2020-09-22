import Vapor
import KognitaCore

extension Subject: ModelParameterRepresentable {}

public protocol SubjectAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection {
    func create(on req: Request) throws -> EventLoopFuture<Subject.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<Subject.Update.Response>
    func retrive(on req: Request) throws -> EventLoopFuture<Subject>
    func retriveAll(_ req: Request) throws -> EventLoopFuture<[Subject]>
    func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details>
    func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func getListContent(_ req: Request) throws -> EventLoopFuture<Dashboard>
    func export(on req: Request) throws -> EventLoopFuture<SubjectExportContent>
    func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus>
    func makeSubject(inactive req: Request) throws -> EventLoopFuture<HTTPStatus>
    func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func compendium(on req: Request) throws -> EventLoopFuture<Subject.Compendium>
    func testStats(on req: Request) throws -> EventLoopFuture<[SubjectTest.DetailedResult]>
    func overview(on req: Request) throws -> EventLoopFuture<Subject.Overview>
}

extension Subject.Compendium: Content {}

extension SubjectAPIControlling {

    public func boot(routes: RoutesBuilder) throws {

        let subjects = routes.grouped("subjects")
        let subjectInstance = subjects.grouped(Subject.parameter)

        register(create: create(on:), router: subjects)
        register(update: update(on:), router: subjects, parameter: Subject.self)
        register(delete: subjects, parameter: Subject.self)
        register(retrive: retrive(on:), router: subjects, parameter: Subject.self)
        register(retriveAll: retriveAll(_:), router: subjects)

        subjectInstance.get("stats", use: self.testStats(on: ))
        subjectInstance.get("export", use: self.export)
        subjectInstance.get("compendium", use: self.compendium(on: ))
        subjectInstance.post("active", use: self.makeSubject(active: ))
        subjectInstance.post("inactive", use: self.makeSubject(inactive: ))
        subjectInstance.post("grant-moderator", use: self.grantPriveleges(on: ))
        subjectInstance.post("revoke-moderator", use: self.revokePriveleges(on: ))

//        router.get  ("subjects/export",                     use: Self.exportAll)
        routes.post("subjects", "import", use: self.importContent)
        subjectInstance.post("import-peer", use: self.importContentPeerWise)
    }
}
