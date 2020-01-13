import Vapor
@testable import KognitaCore

class TopicRepositoryMock: TopicRepository {

    class Logger: TestLogger {
        enum Entry {
            case getTopics(subject: Subject)
            case create(data: Topic.Create.Data, user: User?)
            case delete(Topic)
        }

        var logs: [Entry] = []

        static let shared = Logger()
    }

    static func getTopics(in subject: Subject, conn: DatabaseConnectable) throws -> EventLoopFuture<[Topic]> {
        Logger.shared.log(entry: .getTopics(subject: subject))
        return conn.future([])
    }

    static func create(from content: Topic.Create.Data, by user: User?, on conn: DatabaseConnectable) throws -> EventLoopFuture<Topic> {
        Logger.shared.log(entry: .create(data: content, user: user))
        return conn.databaseConnection(to: .psql)
            .map { conn in
                try Topic.create(on: conn)
        }
    }

    static func all(on conn: DatabaseConnectable) throws -> EventLoopFuture<[Topic]> {
        return conn.future([])
    }

    static func update(model: Topic, to data: Topic.Edit.Data, by user: User, on conn: DatabaseConnectable) throws -> EventLoopFuture<Topic> {
        conn.future(model)
    }

    static func delete(model: Topic, by user: User?, on conn: DatabaseConnectable) throws -> EventLoopFuture<Void> {
        Logger.shared.log(entry: .delete(model))
        return conn.future()
    }
}
