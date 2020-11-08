import Vapor
import KognitaCore
import Mailgun
import PostgresKit

extension Optional {

    var isDefined: Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
}

public protocol APIControllerCollection: RouteCollection {
    var subjectController: SubjectAPIControlling { get }
    var topicController: TopicAPIControlling { get }
    var subtopicController: SubtopicAPIControlling { get }
    var multipleChoiceTaskController: MultipleChoiseTaskAPIControlling { get }
    var typingTaskController: FlashCardTaskAPIControlling { get }
    var practiceSessionController: PracticeSessionAPIControlling { get }
    var taskResultController: TaskResultAPIControlling { get }
    var subjectTestController: SubjectTestAPIControlling { get }
    var testSessionController: TestSessionAPIControlling { get }
    var taskDiscussionController: TaskDiscussionAPIControlling { get }
    var taskDiscussionResponseController: TaskDiscussionResponseAPIControlling { get }
    var taskSolutionController: TaskSolutionAPIControlling { get }
    var userController: UserAPIControlling { get }
    var lectureNoteController: LectureNoteAPIController { get }
    var lectureNoteTakingSessionController: LectureNoteTakingSessionAPIController { get }
    var examController: ExamAPIController { get }
    var examSessionController: ExamSessionAPIController { get }
}

public struct APIControllers: APIControllerCollection {

    public var subjectController: SubjectAPIControlling
    public var topicController: TopicAPIControlling
    public var subtopicController: SubtopicAPIControlling
    public var multipleChoiceTaskController: MultipleChoiseTaskAPIControlling
    public var typingTaskController: FlashCardTaskAPIControlling
    public var practiceSessionController: PracticeSessionAPIControlling
    public var taskResultController: TaskResultAPIControlling
    public var subjectTestController: SubjectTestAPIControlling
    public var testSessionController: TestSessionAPIControlling
    public var taskDiscussionController: TaskDiscussionAPIControlling
    public var taskDiscussionResponseController: TaskDiscussionResponseAPIControlling
    public var taskSolutionController: TaskSolutionAPIControlling
    public var userController: UserAPIControlling
    public var lectureNoteController: LectureNoteAPIController
    public var lectureNoteTakingSessionController: LectureNoteTakingSessionAPIController
    public var lectureNoteRecapSessionController: LectureNoteRecapSessionAPIController
    public var examController: ExamAPIController
    public var examSessionController: ExamSessionAPIController

    public func boot(routes: RoutesBuilder) throws {

        try routes.register(collection: userController)

        let auth = routes.grouped(
            User.sessionAuthMiddleware(),
            User.bearerAuthMiddleware(),
            User.guardMiddleware()
        )
        try auth.register(collection: subjectController)
        try auth.register(collection: topicController)
        try auth.register(collection: subtopicController)
        try auth.register(collection: multipleChoiceTaskController)
        try auth.register(collection: typingTaskController)
        try auth.register(collection: practiceSessionController)
        try auth.register(collection: testSessionController)
        try auth.register(collection: subjectTestController)
        try auth.register(collection: taskDiscussionController)
        try auth.register(collection: taskDiscussionResponseController)
        try auth.register(collection: taskSolutionController)
        try auth.register(collection: taskResultController)
        try auth.register(collection: lectureNoteController)
        try auth.register(collection: lectureNoteTakingSessionController)
        try auth.register(collection: lectureNoteRecapSessionController)
        try auth.register(collection: examController)
        try auth.register(collection: examSessionController)
    }
}

extension APIControllers {
    public static func defaultControllers() -> APIControllers {
        APIControllers(
            subjectController: Subject.DefaultAPIController(),
            topicController: Topic.DefaultAPIController(),
            subtopicController: Subtopic.DefaultAPIController(),
            multipleChoiceTaskController: MultipleChoiceTask.DefaultAPIController(),
            typingTaskController: TypingTask.DefaultAPIController(),
            practiceSessionController: PracticeSession.DefaultAPIController(),
            taskResultController: TaskResultAPIController(),
            subjectTestController: SubjectTest.DefaultAPIController(),
            testSessionController: TestSession.DefaultAPIController(),
            taskDiscussionController: TaskDiscussion.DefaultAPIController(),
            taskDiscussionResponseController: TaskDiscussionResponse.DefaultAPIController(),
            taskSolutionController: TaskSolution.DefaultAPIController(),
            userController: User.DefaultAPIController(),
            lectureNoteController: LectureNoteDatabaseAPIController(),
            lectureNoteTakingSessionController: LectureNote.TakingSession.APIController(),
            lectureNoteRecapSessionController: LectureNote.RecapSession.APIController(),
            examController: DefaultExamAPIController(),
            examSessionController: DefaultExamSessionAPIController()
        )
    }
}

extension Request {
    public var controllers: APIControllers { .defaultControllers() }
}

public struct KognitaAPIProvider: LifecycleHandler {

    let env: Environment

    public init(env: Environment) {
        self.env = env
    }

    public func register(_ app: Application) throws {
        try KognitaAPI.setupApi(for: app, routes: app.grouped("api"))

        if env == .testing {
            try KognitaAPI.setupForTesting(app: app)
        }

        if Environment.get("VAPOR_MIGRATION")?.lowercased() == "true" {
            try! app.autoMigrate().wait()
        }
    }

    public func willBoot(_ application: Application) throws {
        try self.register(application)
    }
}

public class KognitaAPI {

    public static func configMiddleware(config app: Application) {
        app.middleware.use(HTTPSRedirectMiddleware())
    }

    static func setupApi(for app: Application, routes: RoutesBuilder) throws {
        /// In order to upload big files
        KognitaCore.config(app: app)

        setupDatabase(for: app)
        app.verifyEmailSender.use { User.VerifyEmailSender(request: $0) }
        app.resetPasswordSender.use(User.ResetPasswordMailgunSender.init(request: ))

        // Needs to be after addMigrations(), because it relies on the tables created there
        if app.environment == .testing {
            // Register the commands (used to reset the database)
            try setupForTesting(app: app)
        } else {
            setupMailgun(in: app)
        }

        setupTextClient(app: app)
        try APIControllers.defaultControllers().boot(routes: routes.grouped(app.sessions.middleware))
    }

    static func setupTextClient(app: Application) {

        // Localhost testing config
        var baseUrl = "127.0.0.1"
        var port = 443
        var scheme = "https"

        if let baseURL = Environment.get("TEXT_CLIENT_BASE_URL") {
            baseUrl = baseURL
        }
        if let portString = Environment.get("TEXT_CLIENT_PORT"), let portNumber = Int(portString) {
            port = portNumber
        }
        if let schemeOverwrite = Environment.get("TEXT_CLIENT_SCHEME") {
            scheme = schemeOverwrite
        }

        app.textMiningClienting.use { request in
            PythonTextClient(client: request.client, scheme: scheme, baseUrl: baseUrl, port: port, logger: request.logger)
        }
    }

    static func setupForTesting(app: Application) throws {

        app.middleware.use(app.sessions.middleware)
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    }

    /// Configures the mailing service
    private static func setupMailgun(in app: Application) {
        guard let mailgunKey = Environment.get("MAILGUN_KEY"),
            let mailgunDomain = Environment.get("MAILGUN_DOMAIN") else {
                fatalError("Mailgun is NOT activated")
        }
        app.mailgun.configuration = .init(apiKey: mailgunKey)
        app.mailgun.defaultDomain = .init(mailgunDomain, .eu)
    }

    /// Configures the database
    private static func setupDatabase(for app: Application) {

        var maxConnections = 4
        if
            let maxConnectionsEnv = Environment.get("MAX_CONNECTIONS"),
            let customMaxConnections = Int(maxConnectionsEnv)
        {
            maxConnections = customMaxConnections
        } else if app.environment == .testing {
            maxConnections = 2
        }

        // Configure a PostgreSQL database
        let databaseConfig: PostgresConfiguration!

        if let url = Environment.get("DATABASE_URL") {  // Heroku
            guard var psqlConfig = PostgresConfiguration(url: url) else {
                fatalError("Failed to create PostgreSQL Config")
            }
            psqlConfig.tlsConfiguration = .forClient(certificateVerification: .none)
            databaseConfig = psqlConfig
        } else {                                        // Localy testing
            let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
            let username = Environment.get("DATABASE_USER") ?? "matsmollestad"

            var databaseName = "local"
            if let customName = Environment.get("DATABASE_DB") {
                databaseName = customName
            } else if app.environment == .testing {
                databaseName = "testing"
            }
            let databasePort = 5432
            let password = Environment.get("DATABASE_PASSWORD") ?? nil
            databaseConfig = PostgresConfiguration(
                hostname: hostname,
                port: databasePort,
                username: username,
                password: password,
                database: databaseName
            )
        }
        app.databases.use(.postgres(configuration: databaseConfig, maxConnectionsPerEventLoop: maxConnections), as: .psql)
    }
}

class HTTPSRedirectMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.application.environment == Environment.production else {
            return next.respond(to: request)
        }

        let proto = request.headers.first(name: "X-Forwarded-Proto")
            ?? request.url.scheme
            ?? "http"

        guard proto == "https" else {
            guard let host = request.headers.first(name: .host) else {
                return request.eventLoop.future(error: Abort(.badRequest))
            }

            let httpsURL = "https://" + host + request.url.string
            return request.eventLoop.future(request.redirect(to: httpsURL, type: .permanent))
        }

        return next.respond(to: request)
            .map { resp in
                resp.headers.add(
                    name: "Strict-Transport-Security",
                    value: "max-age=31536000; includeSubDomains; preload")
                return resp
            }
    }
}
