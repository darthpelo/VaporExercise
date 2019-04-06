@testable import App
import FluentMySQL

extension User {
    static func create(
        name: String = "Pippo",
        username: String = "pippo",
        on connection: MySQLConnection
    ) throws -> User {
        let user = User(name: name, username: username)
        return try user.save(on: connection).wait()
    }
}
