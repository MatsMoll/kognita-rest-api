import Vapor
import KognitaCore

public protocol CreateModelAPIController {
    associatedtype CreateData: Decodable
    associatedtype CreateResponse: Content
    associatedtype Repository: CreateModelRepository

    var repository: Repository { get }

    func create(on req: Request) throws -> EventLoopFuture<CreateResponse>

    func register(create route: Router)
}

extension CreateModelAPIController {
    public func register(create router: Router) {
        router.post("/", use: self.create)
    }
}

extension CreateModelAPIController
    where
    Repository.CreateData       == CreateData,
    Repository.CreateResponse   == CreateResponse {

    public func create(on req: Request) throws -> EventLoopFuture<CreateResponse> {

        let user = try req.authenticated(User.self)

        return try req.content
            .decode(CreateData.self)
            .flatMap { data in
                try self.repository.create(from: data, by: user)
        }
    }
}
