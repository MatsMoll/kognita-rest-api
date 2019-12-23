import Vapor
import KognitaCore

public protocol CreateModelAPIController {
    associatedtype CreateData: Decodable
    associatedtype CreateResponse: Content
    associatedtype Repository: CreateModelRepository

    static func create(on req: Request) throws -> EventLoopFuture<CreateResponse>

    func register(create route: Router)
}

extension CreateModelAPIController {
    public func register(create router: Router) {
        router.post("/", use: Self.create)
    }
}

extension CreateModelAPIController
    where
    Repository.CreateData       == CreateData,
    Repository.CreateResponse   == CreateResponse
{

    public static func create(on req: Request) throws -> EventLoopFuture<CreateResponse> {

        let user = try req.authenticated(User.self)

        return try req.content
            .decode(CreateData.self)
            .flatMap { data in
                try Repository.create(from: data, by: user, on: req)
        }
    }
}
