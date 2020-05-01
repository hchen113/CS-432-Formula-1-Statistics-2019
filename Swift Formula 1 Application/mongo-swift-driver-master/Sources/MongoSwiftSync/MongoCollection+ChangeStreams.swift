import MongoSwift

extension MongoCollection {
    /**
     * Starts a `ChangeStream` on a collection. The `CollectionType` will be associated with the `fullDocument`
     * field in `ChangeStreamEvent`s emitted by the returned `ChangeStream`. The server will return an error if
     * this method is called on a system collection.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *
     * - Returns: A `ChangeStream` on a specific collection.
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
     */
    public func watch(
        _ pipeline: [Document] = [],
        options: ChangeStreamOptions? = nil,
        session: ClientSession? = nil
    ) throws -> ChangeStream<ChangeStreamEvent<CollectionType>> {
        try self.watch(
            pipeline,
            options: options,
            session: session,
            withEventType: ChangeStreamEvent<CollectionType>.self
        )
    }

    /**
     * Starts a `ChangeStream` on a collection. Associates the specified `Codable` type `T` with the `fullDocument`
     * field in the `ChangeStreamEvent`s emitted by the returned `ChangeStream`. The server will return an error
     * if this method is called on a system collection.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *   - withFullDocumentType: The type that the `fullDocument` field of the emitted `ChangeStreamEvent`s will be
     *                           decoded to.
     *
     * - Returns: A `ChangeStream` on a specific collection.
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
     * Starts a `ChangeStream` on a collection. Associates the specified `Codable` type `T` with the returned
     * `ChangeStream`. The server will return an error if this method is called on a system collection.
     *
     * - Parameters:
     *   - pipeline: An array of aggregation pipeline stages to apply to the events returned by the change stream.
     *   - options: An optional `ChangeStreamOptions` to use when constructing the change stream.
     *   - session: An optional `ClientSession` to use with this change stream.
     *   - withEventType: The type that the entire change stream response will be decoded to and that will be returned
     *                    when iterating through the change stream.
     *
     * - Returns: A `ChangeStream` on a specific collection.
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
     */
    public func watch<EventType: Codable>(
        _ pipeline: [Document] = [],
        options: ChangeStreamOptions? = nil,
        session: ClientSession? = nil,
        withEventType _: EventType.Type
    ) throws -> ChangeStream<EventType> {
        let asyncStream = try self.asyncColl.watch(
            pipeline,
            options: options,
            session: session?.asyncSession,
            withEventType: EventType.self
        ).wait()
        return ChangeStream(wrapping: asyncStream, client: self.client)
    }
}
