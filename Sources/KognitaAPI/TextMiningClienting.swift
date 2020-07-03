import NIO
import Vapor

public protocol TextMiningClienting {
    /// Estimates how similar two text are to each other
    /// - Parameters:
    ///   - first: The first text to compare
    ///   - second: The second text to compare
    ///   - worker: The worker handeling the request
    func similarity(between first: String, and second: String) throws -> EventLoopFuture<ClientResponse>
}

struct TextMiningClientingFactory {
    var make: ((Request) -> TextMiningClienting)?

    mutating func use(_ make: @escaping ((Request) -> TextMiningClienting)) {
        self.make = make
    }
}

extension Application {
    private struct TextMiningClientingKey: StorageKey {
        typealias Value = TextMiningClientingFactory
    }

    var textMiningClienting: TextMiningClientingFactory {
        get { self.storage[TextMiningClientingKey.self] ?? .init() }
        set { self.storage[TextMiningClientingKey.self] = newValue }
    }
}

extension Request {
    var textMiningClienting: TextMiningClienting {
        application.textMiningClienting.make!(self)
    }
}

struct PythonTextClient: TextMiningClienting {

    let client: Client
    let baseUrl: String
    let logger: Logger

    struct SimilarityData: Content {
        let org: String
        let text: String
    }

    func similarity(between first: String, and second: String) throws -> EventLoopFuture<ClientResponse> {

        var url = URI(path: "compare")
        url.host = baseUrl
        logger.log(level: .info, "Sending request \(url)", file: #file, function: #function, line: #line)
        return client.post(
            url,
            headers: .init([
                ("Accept", "application/json, text/plain, */*"),
                ("Content-Type", "application/json")
            ]),
            beforeSend: { (req) in
                try req.content.encode(SimilarityData(org: first, text: second))
            })
            .flatMapErrorThrowing { error in
                self.logger.log(level: .critical, "Error: \(error), when estimating similarity")
                throw error
        }
    }
}
