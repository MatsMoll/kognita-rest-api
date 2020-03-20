import Vapor
import KognitaCore

protocol SubjectAPIControlling:
    CreateModelAPIController,
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
    UpdateData      == Subject.Edit.Data,
    UpdateResponse  == Subject.Edit.Response
{
    static func getDetails(_ req: Request) throws -> EventLoopFuture<Subject.Details>
    static func importContent(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func importContentPeerWise(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func getListContent(_ req: Request) throws -> EventLoopFuture<Subject.ListContent>
    static func export(on req: Request) throws -> EventLoopFuture<SubjectExportContent>
    static func makeSubject(active req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func makeSubject(inactive req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func grantPriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
    static func revokePriveleges(on req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension SubjectAPIControlling {
    public func boot(router: Router) {

        let subjects = router.grouped("subjects")
        let subjectInstance = subjects.grouped(Subject.parameter)

        register(create:        subjects)
        register(delete:        subjects)
        register(update:        subjects)
        register(retrive:       subjects)
        register(retriveAll:    subjects)

        subjectInstance.get("export",  use: Self.export)
        subjectInstance.post("active", use: Self.makeSubject(active: ))
        subjectInstance.post("inactive", use: Self.makeSubject(inactive: ))
        subjectInstance.post("grant-moderator", use: Self.grantPriveleges(on: ))
        subjectInstance.post("revoke-moderator", use: Self.revokePriveleges(on: ))

//        router.get  ("subjects/export",                     use: Self.exportAll)
        router.post ("subjects/import",                     use: Self.importContent)
        subjectInstance.post ("import-peer",                use: Self.importContentPeerWise)
    }
}
