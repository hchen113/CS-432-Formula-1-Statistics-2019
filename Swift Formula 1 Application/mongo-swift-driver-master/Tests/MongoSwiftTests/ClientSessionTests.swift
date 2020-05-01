@testable import MongoSwift
import Nimble
import NIO
import TestsCommon

final class ClientSessionTests: MongoSwiftTestCase {
    func testSession() throws {
        try self.withTestNamespace { client, _, coll in
            let session = client.startSession()
            // chained method calls
            let res = coll.insertOne(["a": 1], session: session)
                .flatMap { _ in
                    coll.findOneAndDelete(["a": 1], session: session)
                }
                .flatMap { _ in
                    coll.countDocuments()
                }

            expect(try res.wait()).to(equal(0))
            try session.end().wait()
        }
    }

    func testWithSession() throws {
        try self.withTestNamespace { client, db, coll in
            // successful result
            let res1 = client.withSession { session in
                coll.insertOne(["a": 1], session: session)
            }
            expect(try res1.wait()).toNot(throwError())

            // test session is closed when withSession is completed
            var escapedSession: ClientSession?
            let res2: EventLoopFuture<Document> = client.withSession { session in
                escapedSession = session
                return db.runCommand(["isMaster": 1], session: session)
            }
            expect(try res2.wait()).toNot(throwError())
            expect(escapedSession?.active).to(beFalse())

            // failed result, unused session
            let res3: EventLoopFuture<Void> = client.withSession { session in
                escapedSession = session
                throw TestError(message: "")
            }

            expect(try res3.wait()).to(throwError())
            expect(escapedSession?.active).to(beFalse())
        }
    }
}
