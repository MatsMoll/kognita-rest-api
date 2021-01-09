import Vapor
import KognitaCore
import Mailgun
import PostgresKit
import Prometheus
import Metrics
import Redis

extension Optional {

    var isDefined: Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
}

/// A protocol containing all the different controllers needed to run the Kognita API
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
    var resourceController: ResourceAPIController { get }
}

/// An instance that contains all the different controllers that are needed to run the api
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
    public var resourceController: ResourceAPIController

    public func boot(routes: RoutesBuilder) throws {

        try routes.register(collection: userController)

        let auth = routes.grouped(
            User.sessionAuthMiddleware(),
            User.bearerAuthMiddleware()
        )
        try auth.register(collection: subjectController)

        let guardedAuth = auth.grouped(User.guardMiddleware())
        try guardedAuth.register(collection: topicController)
        try guardedAuth.register(collection: subtopicController)
        try guardedAuth.register(collection: multipleChoiceTaskController)
        try guardedAuth.register(collection: typingTaskController)
        try guardedAuth.register(collection: practiceSessionController)
        try guardedAuth.register(collection: testSessionController)
        try guardedAuth.register(collection: subjectTestController)
        try guardedAuth.register(collection: taskDiscussionController)
        try guardedAuth.register(collection: taskDiscussionResponseController)
        try guardedAuth.register(collection: taskSolutionController)
        try guardedAuth.register(collection: taskResultController)
        try guardedAuth.register(collection: lectureNoteController)
        try guardedAuth.register(collection: lectureNoteTakingSessionController)
        try guardedAuth.register(collection: lectureNoteRecapSessionController)
        try guardedAuth.register(collection: examController)
        try guardedAuth.register(collection: examSessionController)
        try guardedAuth.register(collection: resourceController)
    }
}

extension APIControllers {
    /// Creates an instance of `APIControllers` that contains the differnet controllers to use
    /// - Returns: A `APIControllers` instance
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
            examSessionController: DefaultExamSessionAPIController(),
            resourceController: DefaultResourceAPIController()
        )
    }
}

extension Request {
    /// Returns the controllers to use on different requests
    public var controllers: APIControllers { .defaultControllers() }
}

/// A provider for the Kognita API
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

/// A class that group different Kognita API setup code
public class KognitaAPI {

    /// Setups the different middlewares needed to run the API for Kognita
    /// - Parameter app: The app to config
    public static func configMiddleware(config app: Application) {
        app.middleware.use(HTTPSRedirectMiddleware())
    }

    /// Setup the Kognita API
    /// - Parameters:
    ///   - app: The app to config the api on
    ///   - routes: The route to use for the api calls
    /// - Throws: If there where any eror when configing
    static func setupApi(for app: Application, routes: RoutesBuilder) throws {
        /// In order to upload big files
        KognitaCore.config(app: app)
        var metricsFactory: MetricsFactory!
        if let promFactory = try? MetricsSystem.prometheus() {
            metricsFactory = promFactory
        } else {
            metricsFactory = PrometheusClient()
            MetricsSystem.bootstrap(metricsFactory)
        }

        setupDatabase(for: app)
        app.verifyEmailSender.use { User.VerifyEmailSender(request: $0) }
        app.resetPasswordSender.use(User.ResetPasswordMailgunSender.init(request: ))

        configMiddleware(config: app)

        // Needs to be after addMigrations(), because it relies on the tables created there
        if app.environment == .testing {
            // Register the commands (used to reset the database)
            try setupForTesting(app: app)
        } else {
            setupMailgun(in: app)
        }

        setupTextClient(app: app, metricsFactory: metricsFactory)
        setupMetrics(router: routes)
        setupSessionCache(for: app)
        setupFeide(for: app)
        try APIControllers.defaultControllers().boot(routes: routes.grouped(app.sessions.middleware))
    }

    /// Setup a call that fetches different metrics
    /// - Parameter router: The root route to use
    static func setupMetrics(router: RoutesBuilder) {
        router.grouped(User.bearerAuthMiddleware())
            .on(.GET, "metrics", body: .collect(maxSize: ByteCount.init(value: 20_000_000))) { req -> EventLoopFuture<String> in

            let user = try req.auth.require(User.self)
            guard user.isAdmin else { return req.eventLoop.future(error: Abort(.forbidden)) }

            let promise = req.eventLoop.makePromise(of: String.self)
            DispatchQueue.global().async {
                do {
                    try MetricsSystem.prometheus().collect(into: promise)
                } catch {
                    promise.fail(error)
                }
            }
            return promise.futureResult
        }
    }

    /// Setup the text analyzer client
    /// - Parameters:
    ///   - app: The app to config the client to
    ///   - metricsFactory: The metrics factory to use when logging data
    static func setupTextClient(app: Application, metricsFactory: MetricsFactory) {

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
            PythonTextClient(
                client: request.client,
                scheme: scheme,
                baseUrl: baseUrl,
                port: port,
                logger: request.logger,
                metricsFactory: metricsFactory
            )
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

    /// Setup Redis a a session cacne if the config var exists
    /// - Parameter app: The app to config the cache to
    private static func setupSessionCache(for app: Application) {
        guard let redisUrl = Environment.get("REDISCLOUD_URL") else {
            // Do no setup as this will use the mem as the cache
            app.sessions.use(.memory)
            app.logger.info("Using in memory for sessions")
            return
        }
        guard let config = try? RedisConfiguration(url: redisUrl) else {
            app.logger.warning("Redis unable to init config based on \(redisUrl)")
            return
        }
        app.logger.info("Using Redis for sessions")
        app.redis.configuration = config
        app.sessions.use(.redis)
    }
    
    private static func setupFeide(for app: Application) {
        guard
            let clientID = Environment.get("FEIDE_CLIENT_ID"),
            let clientSecret = Environment.get("FEIDE_CLIENT_SECRET"),
            let authBaseUri = Environment.get("FEIDE_AUTH_BASE_URL"),
            let apiBaseUri = Environment.get("FEIDE_API_BASE_URL"),
            let callbackUri = Environment.get("FEIDE_CALLBACK_URI")
        else { fatalError("Missing some of the env variables for setting up the Feide service") }
        
        let config = FeideClient.Config(
            authBaseUri: authBaseUri,
            apiBaseUri: apiBaseUri,
            clientID: clientID,
            clientSecret: clientSecret,
            callbackUri: callbackUri
        )
        app.feideClient.use { FeideClient(config: config, client: $0.client) }
    }
}

extension HTTPCookies {
    
    public var isFeideLogin: Bool {
        get {
            guard let cookie = self.all["feide-login"] else { return false }
            return cookie.string == "true"
        }
        set {
            if newValue {
                self.all["feide-login"] = .init(string: "true")
            } else {
                self.all["feide-login"] = .init(string: "false", expires: .now)
            }
        }
    }
}
