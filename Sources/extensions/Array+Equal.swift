import Foundation

extension Array where Element: Comparable {
    static func ==(lhs: Array, rhs: Array) -> Bool {
        return lhs.sorted() == rhs.sorted() && lhs.count == rhs.count
    }
}
