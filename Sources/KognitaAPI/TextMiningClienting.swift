import NIO
import Vapor

public protocol TextMiningClienting: Service {
    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<HTTPResponse>
}


class PythonTextClient: TextMiningClienting {

    let httpSchema: HTTPScheme
    let hostname: String
    let port: Int?

    internal init(httpSchema: HTTPScheme = .https, hostname: String, port: Int?) {
        self.httpSchema = httpSchema
        self.hostname = hostname
        self.port = port
    }

    struct SimilarityData: Codable {
        let org: String
        let text: String
    }

    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<HTTPResponse> {

        let body = try JSONEncoder().encode(SimilarityData(org: first, text: second))

        return HTTPClient
            .connect(scheme: httpSchema, hostname: hostname, port: port, on: worker)
            .flatMap { client in

            let request = HTTPRequest(
                method: .POST,
                url: "/compare",
                headers: .init([
                    ("Accept", "application/json, text/plain, */*"),
                    ("Content-Type", "application/json")
                ]),
                body: body
            )

            return client.send(request)
        }
    }
}
