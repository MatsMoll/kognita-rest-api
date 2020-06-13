import Vapor
import KognitaCore

extension Subject: ModelParameterRepresentable {}

public protocol SubjectAPIControlling: CreateModelAPIController,
    UpdateModelAPIController,
    DeleteModelAPIController,
    RetriveModelAPIController,
    RetriveAllModelsAPIController,
    RouteCollection
    where
    Repository: SubjectRepositoring,
    Model           == Subject,
    ModelResponse   == Subject,
    CreateData      == Subject.Create.Data,
    CreateResponse  == Subject.Create.Response,
    UpdateData      == Subject.Update.Data,
    UpdateResponse  == Subject.Update.Response {
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
}

extension SubjectAPIControlling {
    public func boot(router: Router) {

        let subjects = router.grouped("subjects")
        let subjectInstance = subjects.grouped(Subject.parameter)

        register(create: subjects)
        register(delete: subjects)
        register(update: subjects)
        register(retrive: subjects)
        register(retriveAll: subjects)

        subjectInstance.get("stats", use: self.testStats(on: ))
        subjectInstance.get("export", use: self.export)
        subjectInstance.get("compendium", use: self.compendium(on: ))
        subjectInstance.post("active", use: self.makeSubject(active: ))
        subjectInstance.post("inactive", use: self.makeSubject(inactive: ))
        subjectInstance.post("grant-moderator", use: self.grantPriveleges(on: ))
        subjectInstance.post("revoke-moderator", use: self.revokePriveleges(on: ))

//        router.get  ("subjects/export",                     use: Self.exportAll)
        router.post("subjects/import", use: self.importContent)
        subjectInstance.post("import-peer", use: self.importContentPeerWise)
    }
}
