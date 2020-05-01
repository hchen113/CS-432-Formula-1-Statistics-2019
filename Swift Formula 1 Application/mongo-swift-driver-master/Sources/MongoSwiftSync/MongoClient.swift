import MongoSwift
import NIO

/// A MongoDB Client providing a synchronous API.
public class MongoClient {
    /// Encoder whose options are inherited by databases derived from this client.
    public var encoder: BSONEncoder { self.asyncClient.encoder }

    /// Decoder whose options are inherited by databases derived from this client.
    public var decoder: BSONDecoder { self.asyncClient.decoder }

    /// The read concern set on this client, or nil if one is not set.
    public var readConcern: ReadConcern? { self.asyncClient.readConcern }

    /// The `ReadPreference` set on this client.
    public var readPreference: ReadPreference { self.asyncClient.readPreference }

    /// The write concern set on this client, or nil if one is not set.
    public var writeConcern: WriteConcern? { self.asyncClient.writeConcern }

    /// The `EventLoopGroup` being used by the underlying async client.
    private let eventLoopGroup: MultiThreadedEventLoopGroup

    /// The underlying async client.
    internal let asyncClient: MongoSwift.MongoClient

    /**
     * Create a new client connection to a MongoDB server. For options that included in both the connection string URI
     * and the ClientOptions struct, the final value is set in descending order of priority: the value specified in
     * ClientOptions (if non-nil), the value specified in the URI, or the default value if both are unset.
     *
     * - Parameters:
     *   - connectionString: the connection string to connect to.
     *   - options: optional `ClientOptions` to use for this client
     *
     * - SeeAlso: https://docs.mongodb.com/manual/reference/connection-string/
     *
     * - Throws:
     *   - A `InvalidArgumentError` if the connection string passed in is improperly formatted.
     *   - A `InvalidArgumentError` if the connection string specifies the use of TLS but libmongoc was not
     *     built with TLS support.
     */
    public init(_ connectionString: String = "mongodb://localhost:27017", options: ClientOptions? = nil) throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 5)
        do {
            self.asyncClient = try MongoSwift.MongoClient(connectionString, using: eventLoopGroup, options: options)
            self.eventLoopGroup = eventLoopGroup
        } catch {
            try eventLoopGroup.syncShutdownGracefully()
            throw error
        }
    }

    deinit {
        do {
            try self.asyncClient.shutdown().wait()
        } catch {
            assertionFailure("Error closing async client: \(error)")
        }

        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            assertionFailure("Error shutting down event loop group: \(error)")
        }
    }

    /// Starts a new `ClientSession` with the provided options.
    public func startSession(options: ClientSessionOptions? = nil) -> ClientSession {
        ClientSession(client: self, options: options)
    }

    /**
     * Starts a new `ClientSession` with the provided options and passes it to the provided closure.
     * The session is only valid within the body of the closure and will be ended after the body completes.
     *
     * - Throws:
     *   - `RuntimeError.compatibilityError` if the deployment does not support sessions.
     */
    public func withSession<T>(
        options: ClientSessionOptions? = nil,
        _ sessionBody: (ClientSession) throws -> T
    ) rethrows -> T {
        let session = self.startSession(options: options)
        defer { session.end() }
        return try sessionBody(session)
    }

    /**
     * Run the `listDatabases` command.
     *
     * - Parameters:
     *   - filter: Optional `Document` specifying a filter that the listed databases must pass. This filter can be based
     *     on the "name", "sizeOnDisk", "empty", or "shards" fields of the output.
     *   - session: Optional `ClientSession` to use when executing this command.
     *
     * - Returns: A `[DatabaseSpecification]` containing the databases matching provided criteria.
     *
     * - Throws:
     *   - `LogicError` if the provided session is inactive.
     *   - `EncodingError` if an error is encountered while encoding the options to BSON.
     *
     * - SeeAlso: https://docs.mongodb.com/manual/reference/command/listDatabases/
     */
    public func listDatabases(
        _ filter: Document? = nil,
        session: ClientSession? = nil
    ) throws -> [DatabaseSpecification] {
        try self.asyncClient.listDatabases(filter, session: session?.asyncSession).wait()
    }

    /**
     * Get a list of `MongoDatabase`s.
     *
     * - Parameters:
     *   - filter: Optional `Document` specifying a filter on the names of the returned databases.
     *   - session: Optional `ClientSession` to use when executing this command
     *
     * - Returns: An Array of `MongoDatabase`s that match the provided filter.
     *
     * - Throws:
     *   - `LogicError` if the provided session is inactive.
     */
    public func listMongoDatabases(
        _ filter: Document? = nil,
        session: ClientSession? = nil
    ) throws -> [MongoDatabase] {
        try self.listDatabaseNames(filter, session: session).map { self.db($0) }
    }

    /**
     * Get a list of names of databases.
     *
     * - Parameters:
     *   - filter: Optional `Document` specifying a filter on the names of the returned databases.
     *   - session: Optional `ClientSession` to use when executing this command
     *
     * - Returns: A `[String]` containing names of databases that match the provided filter.
     *
     * - Throws:
     *   - `LogicError` if the provided session is inactive.
     */
    public func listDatabaseNames(_ filter: Document? = nil, session: ClientSession? = nil) throws -> [String] {
        try self.asyncClient.listDatabaseNames(filter, session: session?.asyncSession).wait()
    }

    /**
     * Gets a `MongoDatabase` instance for the given database name. If an option is not specified in the optional
     * `DatabaseOptions` param, the database will inherit the value from the parent client or the default if
     * the client’s option is not set. To override an option inherited from the client (e.g. a read concern) with the
     * default value, it must be explicitly specified in the options param (e.g. ReadConcern(), not nil).
     *
     * - Parameters:
     *   - name: the name of the database to retrieve
     *   - options: Optional `DatabaseOptions` to use for the retrieved database
     *
     * - Returns: a `MongoDatabase` corresponding to the provided database name
     */
    public func db(_ name: String, options: DatabaseOptions? = nil) -> MongoDatabase {
        MongoDatabase(client: self, asyncDB: self.asyncClient.db(name, options: options))
    }

    /**
     * Starts a `ChangeStream` on a `MongoClient`. Allows the client to observe all changes in a cluster -
     * excluding system collections and the "config", "local", and "admin" databases.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *
     * - Returns: a `ChangeStream` on all collections in all databases in a cluster.
     *
     * - Throws:
     *   - `CommandError` if an error occurs on the server while creating the change stream.
     *   - `InvalidArgumentError` if the options passed formed an invalid combination.
     *   - `InvalidArgumentError` if the `_id` field is projected out of the change stream documents by the
     *     pipeline.
     *
     * - SeeAlso:
     *   - https://docs.mongodb.com/manual/changeStreams/
     *   - https://docs.mongodb.com/manual/meta/aggregation-quick-reference/
     *   - https://docs.mongodb.com/manual/reference/system-collections/
     *
     * - Note: Supported in MongoDB version 4.0+ only.
     */
    public func watch(
        _ pipeline: [Document] = [],
        options: ChangeStreamOptions? = nil,
        session: ClientSession? = nil
    ) throws -> ChangeStream<ChangeStreamEvent<Document>> {
        try self.watch(
            pipeline,
            options: options,
            session: session,
            withEventType: ChangeStreamEvent<Document>.self
        )
    }

    /**
     * Starts a `ChangeStream` on a `MongoClient`. Allows the client to observe all changes in a cluster -
     * excluding system collections and the "config", "local", and "admin" databases. Associates the specified
     * `Codable` type `T` with the `fullDocument` field in the `ChangeStreamEvent`s emitted by the returned
     * `ChangeStream`.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *   - withFullDocumentType: The type that the `fullDocument` field of the emitted `ChangeStreamEvent`s will be
     *                           decoded to.
     *
     * - Returns: A `ChangeStream` on all collections in all databases in a cluster.
     *
     * - Throws:
     *   - `CommandError` if an error occurs on the server while creating the change stream.
     *   - `InvalidArgumentError` if the options passed formed an invalid combination.
     *   - `InvalidArgumentError` if the `_id` field is projected out of the change stream documents by the
     *     pipeline.
     *
     * - SeeAlso:
     *   - https://docs.mongodb.com/manual/changeStreams/
     *   - https://docs.mongodb.com/manual/meta/aggregation-quick-reference/
     *   - https://docs.mongodb.com/manual/reference/system-collections/
     *
     * - Note: Supported in MongoDB version 4.0+ only.
     */
    public func watch<FullDocType: Codable>(
        _ pipeline: [Document] = [],
        options: ChangeStreamOptions? = nil,
        session: ClientSession? = nil,
        withFullDocumentType _: FullDocType.Type
    ) throws -> ChangeStream<ChangeStreamEvent<FullDocType>> {
        try self.watch(
            pipeline,
            options: options,
            session: session,
            withEventType: ChangeStreamEvent<FullDocType>.self
        )
    }

    /**
     * Starts a `ChangeStream` on a `MongoClient`. Allows the client to observe all changes in a cluster -
     * excluding system collections and the "config", "local", and "admin" databases. Associates the specified
     * `Codable` type `T` with the returned `ChangeStream`.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *   - withEventType: The type that the entire change stream response will be decoded to and that will be returned
     *                    when iterating through the change stream.
     *
     * - Returns: A `ChangeStream` on all collections in all databases in a cluster.
     *
     * - Throws:
     *   - `CommandError` if an error occurs on the server while creating the change stream.
     *   - `InvalidArgumentError` if the options passed formed an invalid combination.
     *   - `InvalidArgumentError` if the `_id` field is projected out of the change stream documents by the
     *     pipeline.
     *
     * - SeeAlso:
     *   - https://docs.mongodb.com/manual/changeStreams/
     *   - https://docs.mongodb.com/manual/meta/aggregation-quick-reference/
     *   - https://docs.mongodb.com/manual/reference/system-collections/
     *
     * - Note: Supported in MongoDB version 4.0+ only.
     */
    public func watch<EventType: Codable>(
        _ pipeline: [Document] = [],
        options: ChangeStreamOptions? = nil,
        session: ClientSession? = nil,
        withEventType _: EventType.Type
    ) throws -> ChangeStream<EventType> {
        let asyncStream = try self.asyncClient.watch(
            pipeline,
            options: options,
            session: session?.asyncSession,
            withEventType: EventType.self
        ).wait()

        return ChangeStream(wrapping: asyncStream, client: self)
    }

    /**
     * Attach a `CommandEventHandler` that will receive `CommandEvent`s emitted by this client.
     *
     * Note: the client stores a weak reference to this handler, so it must be kept alive separately in order for it
     * to continue to receive events.
     */
    public func addCommandEventHandler<T: CommandEventHandler>(_ handler: T) {
        self.asyncClient.addCommandEventHandler(handler)
    }

    /**
     * Attach a callback that will receive `CommandEvent`s emitted by this client.
     *
     * Note: if the provided callback captures this client, it must do so weakly. Otherwise, it will constitute a
     * strong reference cycle and potentially result in memory leaks.
     */
    public func addCommandEventHandler(_ handlerFunc: @escaping (CommandEvent) -> Void) {
        self.asyncClient.addCommandEventHandler(handlerFunc)
    }

    /**
     * Attach an `SDAMEventHandler` that will receive `SDAMEvent`s emitted by this client.
     *
     * Note: the client stores a weak reference to this handler, so it must be kept alive separately in order for it
     * to continue to receive events.
     */
    public func addSDAMEventHandler<T: SDAMEventHandler>(_ handler: T) {
        self.asyncClient.addSDAMEventHandler(handler)
    }

    /**
     * Attach a callback that will receive `SDAMEvent`s emitted by this client.
     *
     * Note: if the provided callback captures this client, it must do so weakly. Otherwise, it will constitute a
     * strong reference cycle and potentially result in memory leaks.
     */
    public func addSDAMEventHandler(_ handlerFunc: @escaping (SDAMEvent) -> Void) {
        self.asyncClient.addSDAMEventHandler(handlerFunc)
    }
}

extension MongoClient: Equatable {
    public static func == (lhs: MongoClient, rhs: MongoClient) -> Bool {
        lhs.asyncClient == rhs.asyncClient
    }
}
