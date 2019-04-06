
import FluentMySQL
import Vapor

public func configure(
    _: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    try services.register(FluentMySQLProvider())

    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    var databases = DatabasesConfig()

    let databaseName: String
    let databasePort: Int

    if env == .testing {
        databaseName = "vapor-test"
        databasePort = 3307
    } else {
        databaseName = "vapor"
        databasePort = 3306
    }
    let databaseConfig = MySQLDatabaseConfig(
        hostname: "localhost",
        port: databasePort,
        username: "vapor",
        password: "password",
        database: databaseName
    )

    let database = MySQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .mysql)
    services.register(databases)

    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Acronym.self, database: .mysql)
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: AcronymCategoryPivot.self, database: .mysql)
    services.register(migrations)

    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
}
