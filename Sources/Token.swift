import Foundation

public enum Token: Equatable {
    case leftParen, rightParen, semicolon
    case identifier(String)
    case number(Double)
    case `operator`(BinaryOperator)
    case unit(String)
    
    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.leftParen, .leftParen), (.rightParen, .rightParen),
             (.semicolon, .semicolon):
            return true
        case let (.identifier(id1), .identifier(id2)):
            return id1 == id2
        case let (.number(n1), .number(n2)):
            return n1 == n2
        case let (.operator(op1), .operator(op2)):
            return op1 == op2
        case let (.unit(u1), .unit(u2)):
            return u1 == u2
        default:
            return false
        }
    }
    
    public static func !=(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.leftParen, .leftParen), (.rightParen, .rightParen),
             (.semicolon, .semicolon):
            return false
        case (.identifier(_), .identifier(_)):
            return false
        case (.number(_), .number(_)):
            return false
        case (.operator(_), .operator(_)):
            return false
        case (.unit(_), .unit(_)):
            return false
        default:
            return true
        }
    }
}
