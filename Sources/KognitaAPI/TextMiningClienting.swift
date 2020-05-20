import NIO
import Vapor

public protocol TextMiningClienting: Service {
    /// Estimates how similar two text are to each other
    /// - Parameters:
    ///   - first: The first text to compare
    ///   - second: The second text to compare
    ///   - worker: The worker handeling the request
    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<Response>
}

struct PythonTextClient: TextMiningClienting {

    let client: Client
    let baseUrl: String
    let logger: Logger

    struct SimilarityData: Content {
        let org: String
        let text: String
    }

    func similarity(between first: String, and second: String, on worker: Worker) throws -> EventLoopFuture<Response> {

        let url = baseUrl + "/compare"
        logger.log("Sending request \(url)", at: .info, file: #file, function: #function, line: #line, column: #column)
        return client.post(
            url,
            headers: .init([
                ("Accept", "application/json, text/plain, */*"),
                ("Content-Type", "application/json")
            ]),
            beforeSend: { (req) in
                try req.content.encode(SimilarityData(org: first, text: second))
            })
    }
}
