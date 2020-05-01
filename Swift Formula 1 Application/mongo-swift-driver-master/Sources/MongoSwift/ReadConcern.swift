import CLibMongoC

/// A struct to represent a MongoDB read concern.
public struct ReadConcern: Codable {
    /// An enumeration of possible ReadConcern levels.
    public enum Level: RawRepresentable, Codable, Equatable {
        /// See https://docs.mongodb.com/manual/reference/read-concern-local/
        case local
        /// See https://docs.mongodb.com/manual/reference/read-concern-available/
        case available
        /// See https://docs.mongodb.com/manual/reference/read-concern-majority/
        case majority
        /// See https://docs.mongodb.com/manual/reference/read-concern-linearizable/
        case linearizable
        /// See https://docs.mongodb.com/master/reference/read-concern-snapshot/
        case snapshot
        /// Any other read concern level not covered by the other cases.
        /// This case is present to provide forwards compatibility with any
        /// future read concerns which may be added to new versions of MongoDB.
        case other(level: String)

        public var rawValue: String {
            switch self {
            case .local:
                return "local"
            case .available:
                return "available"
            case .majority:
                return "majority"
            case .linearizable:
                return "linearizable"
            case .snapshot:
                return "snapshot"
            case let .other(l):
                return l
            }
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "local":
                self = .local
            case "available":
                self = .available
            case "majority":
                self = .majority
            case "linearizable":
                self = .linearizable
            default:
                self = .other(level: rawValue)
            }
        }
    }

    /// The level of this `ReadConcern`, or `nil` if the level is not set.
    public var level: Level?

    /// Indicates whether this `ReadConcern` is the server default.
    public var isDefault: Bool {
        self.level == nil
    }

    // Initializes a new `ReadConcern` with the same level as the provided `mongoc_read_concern_t`.
    // The caller is responsible for freeing the original `mongoc_read_concern_t`.
    internal init(from readConcern: OpaquePointer) {
        if let level = mongoc_read_concern_get_level(readConcern) {
            self.level = Level(rawValue: String(cString: level))
        }
    }

    /// Initialize a new `ReadConcern` with a `Level`.
    public init(_ level: Level) {
        self.level = level
    }

    /// Initialize a new `ReadConcern` from a `String` corresponding to a read concern level.
    public init(_ level: String) {
        self.level = Level(rawValue: level)
    }

    /// Initialize a new empty `ReadConcern`.
    public init() {
        self.level = nil
    }

    /**
     * Creates a new `mongoc_read_concern_t` based on this `ReadConcern` and passes it to the provided closure.
     * The pointer is only valid within the body of the closure and will be freed after the body completes.
     */
    internal func withMongocReadConcern<T>(_ body: (OpaquePointer) throws -> T) rethrows -> T {
        let readConcern: OpaquePointer = mongoc_read_concern_new()
        defer { mongoc_read_concern_destroy(readConcern) }
        if let level = self.level {
            mongoc_read_concern_set_level(readConcern, level.rawValue)
        }
        return try body(readConcern)
    }
}

/// An extension of `ReadConcern` to make it `CustomStringConvertible`.
extension ReadConcern: CustomStringConvertible {
    /// Returns the relaxed extended JSON representation of this `ReadConcern`.
    /// On error, an empty string will be returned.
    public var description: String {
        guard let description = try? BSONEncoder().encode(self).description else {
            return ""
        }
        return description
    }
}

/// An extension of `ReadConcern` to make it `Equatable`.
extension ReadConcern: Equatable {
    public static func == (lhs: ReadConcern, rhs: ReadConcern) -> Bool {
        lhs.level == rhs.level
    }
}
