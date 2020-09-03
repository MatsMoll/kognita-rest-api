import Vapor
@testable import KognitaCore

extension Topic {
    fileprivate static let dummy: Topic = Topic(id: 0, subjectID: 0, name: "", chapter: 1)
}

struct TopicRepositoryMock: TopicRepository {

    func topicFor(taskID: Int) -> EventLoopFuture<Topic> {
        eventLoop.future(.dummy)
    }

    class Logger: TestLogger {
        enum Entry {
            case getTopics(subjectID: Subject.ID)
            case create(data: Topic.Create.Data, user: User?)
            case delete(Topic.ID)
        }

        var logs: [Entry] = []
    }

    var logger = Logger()
    var eventLoop: EventLoop

    func getTopicsWith(subjectID: Subject.ID) -> EventLoopFuture<[Topic]> {
        logger.log(entry: .getTopics(subjectID: subjectID))
        return eventLoop.future([])
    }

    func exportTasks(in topic: Topic) throws -> EventLoopFuture<TopicExportContent> {
        eventLoop.future(error: Abort(.notImplemented))
    }

    func exportTopics(in subject: Subject) throws -> EventLoopFuture<SubjectExportContent> {
        eventLoop.future(error: Abort(.notImplemented))
    }

    func getTopicResponses(in subject: Subject) throws -> EventLoopFuture<[Topic]> {
        eventLoop.future([])
    }

    func importContent(from content: TopicExportContent, in subject: Subject) throws -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    func importContent(from content: SubtopicExportContent, in topic: Topic) throws -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    func getTopicsWithTaskCount(in subject: Subject) throws -> EventLoopFuture<[Topic.WithTaskCount]> {
        eventLoop.future([])
    }

    func create(from content: Topic.Create.Data, by user: User?) throws -> EventLoopFuture<Topic> {
        logger.log(entry: .create(data: content, user: user))
        return eventLoop.future(.dummy)
    }

    func updateModelWith(id: Int, to data: Topic.Update.Data, by user: User) throws -> EventLoopFuture<Topic> {
        eventLoop.future(.dummy)
    }

    func deleteModelWith(id: Int, by user: User?) throws -> EventLoopFuture<Void> {
        logger.log(entry: .delete(id))
        return eventLoop.future()
    }

    func find(_ id: Int, or error: Error) -> EventLoopFuture<Topic> {
        eventLoop.future(error: error)
    }

    func find(_ id: Int) -> EventLoopFuture<Topic?> {
        eventLoop.future(nil)
    }

    func all() throws -> EventLoopFuture<[Topic]> {
        eventLoop.future([])
    }
}
