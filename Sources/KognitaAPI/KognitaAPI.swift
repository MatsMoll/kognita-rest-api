import Vapor
import KognitaCore
import Mailgun
import FluentPostgreSQL
import Authentication

extension Optional {

    var isDefined: Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
}

public class KognitaAPI {

    public static func setupApi(for router: Router) throws {

        try router.register(collection: User.DefaultAPIController())

        let auth = router.grouped(
            User.tokenAuthMiddleware(),
            User.authSessionsMiddleware(),
            User.guardAuthMiddleware()
        )

        let authControllers: [RouteCollection] = [
            Subject             .DefaultAPIController(),
            Topic               .DefaultAPIController(),
            Subtopic            .DefaultAPIController(),
            MultipleChoiseTask  .DefaultAPIController(),
            FlashCardTask       .DefaultAPIController(),
            PracticeSession     .DefaultAPIController(),
            TaskResult          .DefaultAPIController()
        ]

        try authControllers.forEach {
            try auth.register(collection: $0)
        }
    }

    public static func setupApi(with env: Environment, in services: inout Services) throws {
        /// In order to upload big files
        try services.register(FluentPostgreSQLProvider())
        try services.register(AuthenticationProvider())

        var middlewares = MiddlewareConfig()
        // Enables sessions.
        middlewares.use(SessionsMiddleware.self)
        services.register(middlewares)

        services.register(NIOServerConfig.default(maxBodySize: 20_000_000))

        let migrations = DatabaseMigrations.migrationConfig(enviroment: env)
        services.register(migrations)

        setupDatabase(for: env, in: &services)
        setupMailgun(in: &services)

        // Needs to be after addMigrations(), because it relies on the tables created there
        if env == .testing {
            // Register the commands (used to reset the database)
            var commandConfig = CommandConfig()
            commandConfig.useFluentCommands()
            services.register(commandConfig)
        }
    }

    /// Configures the mailing service
    private static func setupMailgun(in services: inout Services) {
        guard let mailgunKey = Environment.get("MAILGUN_KEY"),
            let mailgunDomain = Environment.get("MAILGUN_DOMAIN") else {
                print("Mailgun is NOT activated")
                return
        }
        let mailgun = Mailgun(apiKey: mailgunKey, domain: mailgunDomain, region: .eu)
        services.register(mailgun, as: Mailgun.self)
    }

    /// Configures the database
    private static func setupDatabase(for enviroment: Environment, in services: inout Services) {

        if Environment.get("STRICT_DATABASE").isDefined {
            services.register(DatabaseConnectionPoolConfig(maxConnections: 2))
        } else {
            services.register(DatabaseConnectionPoolConfig(maxConnections: 3))
        }

        // Configure a PostgreSQL database
        let databaseConfig: PostgreSQLDatabaseConfig!

        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "matsmollestad"

        if let url = Environment.get("DATABASE_URL") {  // Heroku
            guard let psqlConfig = PostgreSQLDatabaseConfig(url: url, transport: .unverifiedTLS) else {
                fatalError("Failed to create PostgreSQL Config")
            }
            databaseConfig = psqlConfig
        } else {                                        // Localy testing
            var databaseName = "local"
            if let customName = Environment.get("DATABASE_DB") {
                databaseName = customName
            } else if enviroment == .testing {
                databaseName = "testing"
            }
            let databasePort = 5432
            let password = Environment.get("DATABASE_PASSWORD") ?? nil
            databaseConfig = PostgreSQLDatabaseConfig(
                hostname: hostname,
                port: databasePort,
                username: username,
                database: databaseName,
                password: password
            )
        }

        let postgres = PostgreSQLDatabase(config: databaseConfig)

        // Register the configured PostgreSQL database to the database config.
        var databases = DatabasesConfig()
        databases.enableLogging(on: .psql)
        databases.add(database: postgres, as: .psql)
        services.register(databases)
    }
}
