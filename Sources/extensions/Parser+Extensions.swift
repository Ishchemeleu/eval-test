import Foundation

extension Character {
    var value: Int32 { return Int32(String(self).unicodeScalars.first!.value) }
    
    var isSpace: Bool { return isspace(value) != 0 }
    
    var isAlphanumeric: Bool { return isalnum(value) != 0 || self == "_" }
}
