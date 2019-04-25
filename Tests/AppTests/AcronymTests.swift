@testable import App
import FluentMySQL
import Vapor
import XCTest

final class AcronymTests: XCTestCase {
    let acronymsURI = "/api/acronyms/"
    let acronymShort = "OMG"
    let acronymLong = "Oh My God"
    let headers = ["Content-Type": "application/json"]
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

    func testAcronymsCanBeRetrievedFromAPI() throws {
        let acronym1 = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        _ = try Acronym.create(on: conn)

        let acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
        XCTAssertEqual(acronyms[0].id, acronym1.id)
    }

    func testAcronymCanBeSavedWithAPI() throws {
        let user = try User.create(on: conn)
        let acronym = Acronym(short: acronymShort, long: acronymLong, userID: user.id!)

        let receivedAcronym = try app.getResponse(to: acronymsURI, method: .POST, headers: ["Content-Type": "application/json"], data: acronym, decodeTo: Acronym.self)

        XCTAssertEqual(receivedAcronym.short, acronymShort)
        XCTAssertEqual(receivedAcronym.long, acronymLong)
        XCTAssertNotNil(receivedAcronym.userID)

        let acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].short, receivedAcronym.short)
        XCTAssertEqual(acronyms[0].long, receivedAcronym.long)
        XCTAssertEqual(acronyms[0].id, receivedAcronym.id)
    }

    func testGettingASingleAcronymFromTheAPI() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)

        let returnedAcronym = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)", decodeTo: Acronym.self)

        XCTAssertEqual(returnedAcronym.short, acronymShort)
        XCTAssertEqual(returnedAcronym.long, acronymLong)
        XCTAssertEqual(returnedAcronym.id, acronym.id)
    }

    func testAcronymCabBeUpdatedWithAPI() throws {
        let user = try User.create(on: conn)
        let acronym = Acronym(short: acronymShort, long: acronymLong, userID: user.id!)

        let receivedAcronym = try app.getResponse(to: acronymsURI, method: .POST, headers: ["Content-Type": "application/json"], data: acronym, decodeTo: Acronym.self)

        let updateAcronym = Acronym(short: "LOL", long: acronymLong, userID: user.id!)

        let updatedAcronym = try app.getResponse(to: "\(acronymsURI)\(receivedAcronym.id!)",
                                                 method: .PUT,
                                                 headers: ["Content-Type": "application/json"],
                                                 data: updateAcronym,
                                                 decodeTo: Acronym.self)

        XCTAssertEqual(updatedAcronym.short, "LOL")
        XCTAssertEqual(updatedAcronym.long, acronymLong)
        XCTAssertEqual(updatedAcronym.id, receivedAcronym.id)
    }

    func testDeleteAcronymWithAPI() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)

        _ = try app.sendRequest(to: "\(acronymsURI)\(acronym.id!)", method: .DELETE)

        let acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 0)
    }

    func testSearchAcronymShort() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        let acronyms = try app.getResponse(to: "\(acronymsURI)search?term=\(acronymShort)", decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
    }
}
