import Vapor
import KognitaCore

extension Subject: ModelParameterRepresentable {}
extension Subject.Export: Content {}
extension Subject.Details: Content {}

public protocol SubjectAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection {
    /// Creates a new Subject
    /// - Parameter req: The HTTP request with the needed data
    func create(on req: Request) throws -> EventLoopFuture<Subject.Create.Response>
    func update(on req: Request) throws -> EventLoopFuture<Subject.Update.Response>
    func retrive(on req: Request) throws -> EventLoopFuture<Subject>
    func retriveAll(_ req: Request) throws -> EventLoopFuture<[Subject]>
    func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details>
    func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func getListContent(_ req: Request) throws -> EventLoopFuture<Dashboard>
    func export(on req: Request) throws -> EventLoopFuture<Subject.Export>
    func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus>
    func makeSubject(inactive req: Request) throws -> EventLoopFuture<HTTPStatus>
    func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    func compendium(on req: Request) throws -> EventLoopFuture<Subject.Compendium>
    func testStats(on req: Request) throws -> EventLoopFuture<[SubjectTest.DetailedResult]>
    func overview(on req: Request) throws -> EventLoopFuture<Subject.Overview>

    /// Return only the active subject
    /// - Parameter req: The request
    func activeSubjects(on req: Request) throws -> EventLoopFuture<[Subject]>

    func importTopic(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    
    func markPotensialSubjects(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension Subject.Compendium: Content {}

extension SubjectAPIControlling {

    public func boot(routes: RoutesBuilder) throws {

        let subjects = routes.grouped("subjects")
        let guardedSubjects = subjects.grouped(User.guardMiddleware())
        let subjectInstance = subjects.grouped(Subject.parameter)
        let guardedSubjectInstance = subjectInstance.grouped(User.guardMiddleware())
        
        subjects.grouped(User.guardMiddleware()).post("mark-potensial", use: markPotensialSubjects(on:))

        subjects.get("active", use: activeSubjects(on:))

        register(create: create(on:), router: subjects)
        register(update: update(on:), router: subjects, parameter: Subject.self)
        register(delete: subjects, parameter: Subject.self)
        register(retrive: retrive(on:), router: subjects, parameter: Subject.self)
        register(retriveAll: retriveAll(_:), router: subjects)

        subjectInstance.get("compendium", use: self.compendium(on: ))
        subjectInstance.get("details", use: self.getDetails)
        guardedSubjectInstance.get("stats", use: self.testStats(on: ))
        guardedSubjectInstance.post("active", use: self.makeSubject(active: ))
        guardedSubjectInstance.post("inactive", use: self.makeSubject(inactive: ))
        guardedSubjectInstance.post("grant-moderator", use: self.grantPriveleges(on: ))
        guardedSubjectInstance.post("revoke-moderator", use: self.revokePriveleges(on: ))

//        router.get  ("subjects/export",                     use: Self.exportAll)
        subjectInstance.on(.GET, "export", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: self.export(on:))
        routes.on(.POST, "subjects", "import", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: self.importContent(on:))
        routes.on(.POST, "import-peer", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: self.importContentPeerWise)
        subjectInstance.on(.POST, "import", "topic", body: .collect(maxSize: ByteCount.init(value: 20_000_000)), use: self.importTopic(on:))
    }
}
