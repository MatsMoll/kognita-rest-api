import Vapor
@testable import KognitaCore

extension Topic {
    fileprivate static let dummy: Topic = Topic(id: 0, subjectID: 0, name: "", chapter: 1)
}

struct TopicRepositoryMock: TopicRepository {
    
    func importContent(from content: Subtopic.Import, in topic: Topic, resourceMap: [Resource.ID : Resource.ID]) throws -> EventLoopFuture<Void> {
        eventLoop.future()
    }
    
    func importContent(from content: Topic.Import, in subjectID: Subject.ID, resourceMap: [Resource.ID : Resource.ID]) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    func getTopicsWithTaskCount(withSubjectID subjectID: Subject.ID) throws -> EventLoopFuture<[Topic.WithTaskCount]> {
        eventLoop.future([])
    }

    func topicsWithSubtopics(subjectID: Subject.ID) -> EventLoopFuture<[Topic.WithSubtopics]> {
        eventLoop.future([])
    }

    func save(topics: [Topic], forSubjectID subjectID: Subject.ID, user: User) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

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

    func exportTasks(in topic: Topic) throws -> EventLoopFuture<Topic.Export> {
        eventLoop.future(error: Abort(.notImplemented))
    }

    func exportTopics(in subject: Subject) throws -> EventLoopFuture<Subject.Export> {
        eventLoop.future(error: Abort(.notImplemented))
    }

    func getTopicResponses(in subject: Subject) throws -> EventLoopFuture<[Topic]> {
        eventLoop.future([])
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
        eventLoop.future(.dummy)
    }

    func find(_ id: Int) -> EventLoopFuture<Topic?> {
        eventLoop.future(nil)
    }

    func all() throws -> EventLoopFuture<[Topic]> {
        eventLoop.future([])
    }
}
