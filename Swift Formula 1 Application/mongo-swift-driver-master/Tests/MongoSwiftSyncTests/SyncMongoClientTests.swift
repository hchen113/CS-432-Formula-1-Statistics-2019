import Foundation
import MongoSwiftSync
import Nimble
import TestsCommon
import XCTest

final class SyncMongoClientTests: MongoSwiftTestCase {
    func testListDatabases() throws {
        let client = try MongoClient.makeTestClient()

        let databases = [
            "db1",
            "empty",
            "db3"
        ]

        try databases.forEach {
            try client.db($0).drop()
            _ = try client.db($0).createCollection("c")
        }

        defer {
            databases.forEach {
                try? client.db($0).drop()
            }
        }

        try client.db("db1").collection("c").insertOne(["a": 1])
        try client.db("db3").collection("c").insertOne(["a": 1])

        let dbInfo = try client.listDatabases()
        expect(dbInfo.map { $0.name }).to(contain(databases))
        expect(Set(dbInfo.map { $0.name }).count).to(equal(dbInfo.count))

        let dbNames = try client.listDatabaseNames()
        expect(dbNames).to(contain(databases))
        expect(Set(dbNames).count).to(equal(dbNames.count))

        let dbObjects = try client.listMongoDatabases()
        expect(dbObjects.map { $0.name }).to(contain(databases))
        expect(Set(dbObjects.map { $0.name }).count).to(equal(dbObjects.count))

        expect(try client.listDatabaseNames(["name": "db1"])).to(equal(["db1"]))

        let topSize = dbInfo.map { $0.sizeOnDisk }.max()!
        expect(try client.listDatabases(["sizeOnDisk": ["$gt": BSON(topSize)]])).to(beEmpty())

        if MongoSwiftTestCase.topologyType == .sharded {
            expect(dbInfo.first?.shards).toNot(beNil())
        }
    }

    func testFailedClientInitialization() {
        // check that we fail gracefully with an error if passing in an invalid URI
        expect(try MongoClient("abcd")).to(throwError(errorType: InvalidArgumentError.self))
    }

    func testServerVersion() throws {
        typealias Version = ServerVersion

        expect(try MongoClient.makeTestClient().serverVersion()).toNot(throwError())

        let three6 = Version(major: 3, minor: 6)
        let three61 = Version(major: 3, minor: 6, patch: 1)
        let three7 = Version(major: 3, minor: 7)

        // test equality
        expect(try Version("3.6")).to(equal(three6))
        expect(try Version("3.6.0")).to(equal(three6))
        expect(try Version("3.6.0-rc1")).to(equal(three6))

        expect(try Version("3.6.1")).to(equal(three61))
        expect(try Version("3.6.1.1")).to(equal(three61))

        // lt
        expect(three6 < three6).to(beFalse())
        expect(three6 < three61).to(beTrue())
        expect(three61 < three6).to(beFalse())
        expect(three61 < three7).to(beTrue())
        expect(three7 < three6).to(beFalse())
        expect(three7 < three61).to(beFalse())

        // lte
        expect(three6 <= three6).to(beTrue())
        expect(three6 <= three61).to(beTrue())
        expect(three61 <= three6).to(beFalse())
        expect(three61 <= three7).to(beTrue())
        expect(three7 <= three6).to(beFalse())
        expect(three7 <= three61).to(beFalse())

        // gt
        expect(three6 > three6).to(beFalse())
        expect(three6 > three61).to(beFalse())
        expect(three61 > three6).to(beTrue())
        expect(three61 > three7).to(beFalse())
        expect(three7 > three6).to(beTrue())
        expect(three7 > three61).to(beTrue())

        // gte
        expect(three6 >= three6).to(beTrue())
        expect(three6 >= three61).to(beFalse())
        expect(three61 >= three6).to(beTrue())
        expect(three61 >= three7).to(beFalse())
        expect(three7 >= three6).to(beTrue())
        expect(three7 >= three61).to(beTrue())

        // invalid strings
        expect(try Version("hi")).to(throwError())
        expect(try Version("3")).to(throwError())
        expect(try Version("3.x")).to(throwError())
    }

    struct Wrapper: Codable, Equatable {
        let _id: String
        let date: Date
        let uuid: UUID
        let data: Data

        static func == (lhs: Wrapper, rhs: Wrapper) -> Bool {
            lhs.date == rhs.date && lhs.data == rhs.data && lhs.uuid == rhs.uuid
        }
    }

    func testCodingStrategies() throws {
        let date = Date(timeIntervalSince1970: 100)
        let uuid = UUID()
        let data = Data(base64Encoded: "dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wZWQgb3ZlciB0aGUgbGF6eSBzaGVlcCBkb2cu")!

        let wrapperWithId = { id in Wrapper(_id: id, date: date, uuid: uuid, data: data) }
        // let wrapper = wrapperWithId("baseline")

        let defaultClient = try MongoClient.makeTestClient()
        let defaultDb = defaultClient.db(Self.testDatabase)
        let collDoc = defaultDb.collection(self.getCollectionName())

        // default behavior is .bsonDate, .binary, .binary
        let collDefault = defaultDb.collection(self.getCollectionName(), withType: Wrapper.self)

        let defaultId: BSON = "default"
        let wrapper = wrapperWithId(defaultId.stringValue!)
        try collDefault.insertOne(wrapper)

        var doc = try collDoc.find(["_id": defaultId]).next()?.get()
        expect(doc).toNot(beNil())
        expect(doc?["date"]?.dateValue).to(equal(date))
        expect(doc?["uuid"]?.binaryValue).to(equal(try Binary(from: uuid)))
        expect(doc?["data"]?.binaryValue).to(equal(try Binary(data: data, subtype: .generic)))

        expect(try collDefault.find(["_id": defaultId]).next()?.get()).to(equal(wrapper))

        // Customize strategies on the client
        let custom = ClientOptions(
            dataCodingStrategy: .base64,
            dateCodingStrategy: .secondsSince1970,
            uuidCodingStrategy: .deferredToUUID
        )
        let clientCustom = try MongoClient.makeTestClient(options: custom)
        let collClient = clientCustom.db(defaultDb.name).collection(collDoc.name, withType: Wrapper.self)

        let collClientId: BSON = "customClient"
        try collClient.insertOne(wrapperWithId(collClientId.stringValue!))

        doc = try collDoc.find(["_id": collClientId]).next()?.get()
        expect(doc).toNot(beNil())
        expect(doc?["date"]?.doubleValue).to(beCloseTo(date.timeIntervalSince1970, within: 0.001))
        expect(doc?["uuid"]?.stringValue).to(equal(uuid.uuidString))
        expect(doc?["data"]?.stringValue).to(equal(data.base64EncodedString()))

        expect(try collClient.find(["_id": collClientId]).next()?.get()).to(equal(wrapper))

        // Construct db with differing strategies from client
        let dbOpts = DatabaseOptions(
            dataCodingStrategy: .binary,
            dateCodingStrategy: .deferredToDate,
            uuidCodingStrategy: .binary
        )
        let dbCustom = clientCustom.db(defaultDb.name, options: dbOpts)
        let collDb = dbCustom.collection(collClient.name, withType: Wrapper.self)

        let customDbId: BSON = "customDb"
        try collDb.insertOne(wrapperWithId(customDbId.stringValue!))

        doc = try collDoc.find(["_id": customDbId]).next()?.get()
        expect(doc).toNot(beNil())
        expect(doc?["date"]?.doubleValue).to(beCloseTo(date.timeIntervalSinceReferenceDate, within: 0.001))
        expect(doc?["uuid"]?.binaryValue).to(equal(try Binary(from: uuid)))
        expect(doc?["data"]?.binaryValue).to(equal(try Binary(data: data, subtype: .generic)))

        expect(try collDb.find(["_id": customDbId]).next()?.get()).to(equal(wrapper))

        // Construct collection with differing strategies from database
        let dbCollOpts = CollectionOptions(
            dataCodingStrategy: .base64,
            dateCodingStrategy: .millisecondsSince1970,
            uuidCodingStrategy: .deferredToUUID
        )
        let collCustom = dbCustom.collection(collClient.name, withType: Wrapper.self, options: dbCollOpts)

        let customDbCollId: BSON = "customDbColl"
        try collCustom.insertOne(wrapperWithId(customDbCollId.stringValue!))
        doc = try collDoc.find(["_id": customDbCollId]).next()?.get()

        expect(doc).toNot(beNil())
        expect(doc?["date"]?.int64Value).to(equal(date.msSinceEpoch))
        expect(doc?["uuid"]?.stringValue).to(equal(uuid.uuidString))
        expect(doc?["data"]?.stringValue).to(equal(data.base64EncodedString()))

        expect(try collCustom.find(["_id": customDbCollId]).next()?.get())
            .to(equal(wrapper))

        try defaultDb.drop()
    }

    // Ensure that sync clients stay alive as long as their child objects are still in scope.
    func testClientLifetimeManagement() throws {
        // Use a weak reference so we can check if the object has been deallocated, but we don't prevent the object
        // from being deallocated ourselves.
        weak var weakClientRef: MongoClient?
        var db: MongoDatabase?
        do {
            let client = try MongoClient.makeTestClient()
            weakClientRef = client
            db = client.db("test")
        }

        // db is still alive, so client should be too, and should be open
        expect(weakClientRef).toNot(beNil())
        expect(try db!.runCommand(["isMaster": 1])).toNot(throwError())

        // once the DB ref goes away, so should the client
        db = nil
        expect(weakClientRef).to(beNil())

        var coll: MongoCollection<Document>?
        do {
            let client = try MongoClient.makeTestClient()
            weakClientRef = client
            coll = client.db("test").collection("test")
        }
        // coll is still alive, so client should be too, and should be open
        expect(weakClientRef).toNot(beNil())
        expect(try coll!.countDocuments()).toNot(throwError())

        // once the coll ref goes away, so should the client
        coll = nil
        expect(weakClientRef).to(beNil())
    }

    func testAPMCallbacks() throws {
        let client = try MongoClient.makeTestClient()

        var commandEvents: [CommandEvent] = []
        client.addCommandEventHandler { event in
            commandEvents.append(event)
        }

        var sdamEvents: [SDAMEvent] = []
        client.addSDAMEventHandler { event in
            sdamEvents.append(event)
        }

        // don't care if command fails, just testing that the events were emitted
        _ = try? client.listDatabases()

        expect(commandEvents).toEventually(haveCount(2)) // wait for started and succeeded / failed
        expect(sdamEvents.isEmpty).toEventually(beFalse())
    }
}
