import CLibMongoC
import Foundation

/// A protocol indicating that a type can be overwritten in-place on a `bson_t`.
internal protocol Overwritable: BSONValue {
    /**
     * Overwrites the value at the current position of the iterator with self.
     *
     * - Throws:
     *   - `InternalError` if the `BSONValue` is an `Int` and cannot be written to BSON.
     *   - `LogicError` if the `BSONValue` is a `Decimal128` or `ObjectId` and is improperly formatted.
     */
    func writeToCurrentPosition(of iter: DocumentIterator) throws
}

extension Bool: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in bson_iter_overwrite_bool(iterPtr, self) }
    }
}

extension Int32: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in bson_iter_overwrite_int32(iterPtr, self) }
    }
}

extension Int64: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in bson_iter_overwrite_int64(iterPtr, self) }
    }
}

extension Double: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in bson_iter_overwrite_double(iterPtr, self) }
    }
}

extension Decimal128: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) throws {
        withUnsafePointer(to: self.decimal128) { decPtr in
            iter.withMutableBSONIterPointer { iterPtr in
                bson_iter_overwrite_decimal128(iterPtr, decPtr)
            }
        }
    }
}

extension ObjectId: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) throws {
        withUnsafePointer(to: self.oid) { oidPtr in
            iter.withMutableBSONIterPointer { iterPtr in bson_iter_overwrite_oid(iterPtr, oidPtr) }
        }
    }
}

extension Timestamp: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in
            bson_iter_overwrite_timestamp(iterPtr, self.timestamp, self.increment)
        }
    }
}

extension Date: Overwritable {
    internal func writeToCurrentPosition(of iter: DocumentIterator) {
        iter.withMutableBSONIterPointer { iterPtr in
            bson_iter_overwrite_date_time(iterPtr, self.msSinceEpoch)
        }
    }
}
