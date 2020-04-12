import NIO
import Vapor

public protocol TextMiningClienting: Service {
    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<HTTPResponse>
}


struct PythonTextClient: TextMiningClienting {

    var httpSchema: HTTPScheme = .https
    let hostname: String
    let port: Int?

    struct SimilarityData: Codable {
        let org: String
        let text: String
    }

    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<HTTPResponse> {
        let body = try JSONEncoder().encode(SimilarityData(org: first, text: second))

        let client = HTTPClient.connect(scheme: httpSchema, hostname: hostname, port: port, on: worker)

        let request = HTTPRequest(
            method: .POST,
            url: "/compare",
            headers: .init([
                ("Accept", "application/json, text/plain, */*"),
                ("Content-Type", "application/json")
            ]),
            body: body
        )

        return client.flatMap { client in
            client.send(request)
        }.map { response in

            if response.status != .ok {
                print(response)
                throw Abort(response.status)
            } else {
                return response
            }
        }
    }
}
