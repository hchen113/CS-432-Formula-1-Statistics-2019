import Foundation

/// An index to "hint" or force MongoDB to use when performing a query.
public enum Hint: Codable {
    /// Specifies an index to use by its name.
    case indexName(String)
    /// Specifies an index to use by a specification `Document` containing the index key(s).
    case indexSpec(Document)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .indexName(name):
            try container.encode(name)
        case let .indexSpec(doc):
            try container.encode(doc)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .indexName(str)
        } else {
            self = .indexSpec(try container.decode(Document.self))
        }
    }
}
