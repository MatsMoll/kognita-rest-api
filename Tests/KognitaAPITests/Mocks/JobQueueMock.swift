import KognitaCore
import Vapor
import XCTest
import FluentPostgreSQL

final class JobQueueMock: JobQueueable {

    private let container: Container

    let expectation: XCTestExpectation = XCTestExpectation()
    var jobDelay: TimeAmount?

    init(container: Container) {
        self.container = container
    }

    func scheduleFutureJob(after delay: TimeAmount, job: @escaping (Container, DatabaseConnectable) throws -> EventLoopFuture<Void>) {
        jobDelay = delay
        container.requestCachedConnection(to: .psql).flatMap { conn in
            try job(self.container, conn)
        }.always {
            self.expectation.fulfill()
        }
    }
}

extension JobQueueMock: ServiceType {
    static var serviceSupports: [Any.Type] {
        return [JobQueueable.self]
    }

    static func makeService(for container: Container) throws -> JobQueueMock {
        return JobQueueMock(container: container)
    }
}
