@testable import App
import FluentMySQL
import Vapor
import XCTest

final class UserTests: XCTestCase {
    let usersName = "Alessio"
    let usersUsername = "darthpelo"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: MySQLConnection!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .mysql).wait()
    }

    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()
    }

    func testUsersCanBeRetrievedFromAPI() throws {
        _ = try User.create(on: conn)

        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: conn
        )

        let users = try app.getResponse(
            to: usersURI,
            decodeTo: [User].self
        )

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
}
