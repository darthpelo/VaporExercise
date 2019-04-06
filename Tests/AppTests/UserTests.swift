@testable import App
import FluentMySQL
import Vapor
import XCTest

final class UserTests: XCTestCase {
    func testUsersCanBeRetrievedFromAPI() throws {
        let revertEnvironmentArgs = ["vapor", "revert", "--all", "-y"]
        // 2
        var revertConfig = Config.default()
        var revertServices = Services.default()
        var revertEnv = Environment.testing
        // 3
        revertEnv.arguments = revertEnvironmentArgs
        // 4
        try App.configure(&revertConfig, &revertEnv, &revertServices)
        let revertApp = try Application(
            config: revertConfig,
            environment: revertEnv,
            services: revertServices
        )
        try App.boot(revertApp)
        // 5
        try revertApp.asyncRun().wait()

        // 6
        let migrateEnvironmentArgs = ["vapor", "migrate", "-y"]
        var migrateConfig = Config.default()
        var migrateServices = Services.default()
        var migrateEnv = Environment.testing
        migrateEnv.arguments = migrateEnvironmentArgs
        try App.configure(&migrateConfig, &migrateEnv, &migrateServices)
        let migrateApp = try Application(
            config: migrateConfig,
            environment: migrateEnv,
            services: migrateServices
        )
        try App.boot(migrateApp)
        try migrateApp.asyncRun().wait()
        let expectedName = "Alessio"
        let expectedUsername = "darthpelo"

        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        try App.configure(&config, &env, &services)
        let app = try Application(
            config: config,
            environment: env,
            services: services
        )
        try App.boot(app)

        let conn = try app.newConnection(to: .mysql).wait()

        let user = User(
            name: expectedName,
            username: expectedUsername
        )
        let savedUser = try user.save(on: conn).wait()
        _ = try User(
            name: "Luke",
            username: "lukes"
        ).save(on: conn).wait()

        let responder = try app.make(Responder.self)

        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "/api/users")!
        )
        let wrappedRequest = Request(http: request, using: app)

        let response = try responder
            .respond(to: wrappedRequest)
            .wait()

        let data = response.http.body.data
        let users = try JSONDecoder().decode([User].self, from: data!)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, expectedName)
        XCTAssertEqual(users[0].username, expectedUsername)
        XCTAssertEqual(users[0].id, savedUser.id)

        conn.close()
    }
}
