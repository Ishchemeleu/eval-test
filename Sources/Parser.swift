import Foundation

public enum BinaryOperator: String {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case mod = "mod"
    case percent = "%"
    case equals = "="
    case power = "^"
    
    static func allCases() -> [BinaryOperator] {
        return [.plus, .minus, .times, .divide, .mod, .equals, .power, .percent]
    }
    
    var symbol: String {
        switch self {
        case .power:
            return "**"
        default:
            return String(self.rawValue)
        }
    }
}

public enum UnitTypes: String {
    case millimeter = "mm"
    case centimeter = "cm"
    case decimeter = "dm"
    case meter = "m"
    case kilometer = "km"
    case milliliter = "mil"
    case squareMillimeter = "mm^2"
    case squareCentimeter = "cm^2"
    case squareDecimeter = "dm^2"
    case squareMeter = "m^2"
    case squareKilometer = "km^2"
    case megaLiter = "ml"
    case centiLiter = "cl"
    case deciLitre = "dl"
    case litre = "l"
    case cubicMillimeter = "mm^3"
    case cubicCentimeter = "cm^3"
    case cubicDecimeter = "dm^3"
    case cubicMeter = "m^3"
    case milligram = "mg"
    case gram = "g"
    case hectogram = "hg"
    case kilogram = "kg"
    case tonne = "ton"
    case second = "s"
    case minute = "min"
    case hour = "h"
    
    case degreeCelcius = "^°C"
    case degreeFahrenheit = "^°F"
    case degreeKelvin = "^°K"
    
    // TODO: Should not use as unit
    case degree = "°"
    case swedishCrown = "kr"
    case perMille = "‰"
    
    static func allCases() -> [UnitTypes] {
        return [millimeter, centimeter, decimeter, meter, kilometer,
                milliliter, litre, megaLiter, centiLiter, deciLitre,
                squareMillimeter, squareCentimeter, squareDecimeter, squareMeter, squareKilometer,
                cubicMillimeter, cubicCentimeter, cubicDecimeter, cubicMeter,
                milligram, gram, hectogram, kilogram, tonne,
                second, minute, hour,
                degreeCelcius, degreeFahrenheit, degreeKelvin,
                degree,
                swedishCrown,
                perMille]
    }
    
    @available(iOS 10.0, *)
    func asUnit() -> Unit {
        switch self {
        // TODO exhaust the enum of supported units
        case .millimeter:
            return UnitLength.millimeters
        case .centimeter:
            return UnitLength.centimeters
        case .decimeter:
            return UnitLength.decimeters
        case .meter:
            return UnitLength.meters
        case .kilometer:
            return UnitLength.kilometers
        case .squareKilometer:
            return UnitArea.squareKilometers
        case .squareMillimeter:
            return UnitArea.squareMillimeters
        case .squareCentimeter:
            return UnitArea.squareCentimeters
        case .squareDecimeter:
            // TODO: Need to verify it, since is not supported by the built in API
            return UnitLength.decimeters
        case .squareMeter:
            return UnitArea.squareMeters
        case .megaLiter:
            return UnitVolume.megaliters
        case .centiLiter:
            return UnitVolume.centiliters
        case .deciLitre:
            return UnitVolume.deciliters
        case .litre:
            return UnitVolume.liters
        case .milliliter:
            return UnitVolume.milliliters
        case .cubicMillimeter:
            return UnitVolume.cubicMillimeters
        case .cubicCentimeter:
            return UnitVolume.cubicCentimeters
        case .cubicDecimeter:
            return UnitVolume.cubicDecimeters
        case .cubicMeter:
            return UnitVolume.cubicMeters
        case .milligram:
            return UnitMass.milligrams
        case .gram:
            return UnitMass.grams
        case .hectogram:
            // TODO: Need to verify it, since is not supported by the built in API
            return UnitMass.grams
        case .kilogram:
            return UnitMass.kilograms
        case .tonne:
            // TODO: Double check it
            return UnitMass.metricTons
        case .second:
            return UnitDuration.seconds
        case .minute:
            return UnitDuration.minutes
        case .hour:
            return UnitDuration.hours
        case .degreeCelcius:
            return UnitTemperature.celsius
        case .degreeFahrenheit:
            return UnitTemperature.fahrenheit
        case .degreeKelvin:
            return UnitTemperature.kelvin
            
        case .degree, .swedishCrown, .perMille:
            return Unit(symbol: self.rawValue)
        }
    }
    
    @available(iOS 10.0, *)
    public func evaluateEquality(value: Double, unitToCompare: UnitTypes, valueToCompare: Double) -> Bool {
        let current = Measurement(value: value, unit: self.asUnit())
        let compare = Measurement(value: valueToCompare, unit: unitToCompare.asUnit())
        return current == compare
    }
}

extension BinaryOperator: Equatable {
    public static func ==(lhs: BinaryOperator, rhs: BinaryOperator) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

indirect enum Expr {
    case number(Double)
    case variable(String)
    case unit(String)
    case binary(Expr, BinaryOperator, Expr, Bool)
}

extension Expr: Equatable {
    static func ==(lhs: Expr, rhs: Expr) -> Bool {
            switch (lhs, rhs) {
            case let (.number(l), .number(r)): return l == r
            case let (.variable(l), .variable(r)): return l == r
            case let (.binary(a, b, c, _), .binary(d, e, f, _)):
                return a == d && b == e && c == f
            case let (.unit(l), .unit(r)):
                return l == r
            default: return false
        }
    }
}

public struct Prototype {
    let name: String
    let params: [String]
}

public struct Definition {
    let prototype: Prototype
    let expr: Expr
}

enum ParseError: Error {
    case unexpectedToken(Token)
    case unexpectedEOF
}

// MARK: - Parser

public class Parser {
    let tokens: [Token]
    var index = 0
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    var currentToken: Token? {
        return index < tokens.count ? tokens[index] : nil
    }
    
    func consumeToken(n: Int = 1) {
        index += n
    }
    
    public func parseFile() throws -> File {
        let file = File()
        while let tok = currentToken {
            switch tok {
            default:
                let expr = try parseExpr()
                try consume(.semicolon)
                file.addExpression(expr)
            }
        }
        return file
    }
    
    /**
     Parses the according Expression(Expr) for the consumed Token.
     
     - returns: An Expression such as number or identifier.
     */
    func parseExpr(isPow: Bool = false, isTimDiv: Bool = false) throws -> Expr {
        guard let token = currentToken else { throw ParseError.unexpectedEOF }
        
        var expr: Expr
        switch token {
        case .leftParen: // ( <expr> )
            expr = try parseleftParen()
        case .number(let value):
            expr = try parseNumber(value)
        case .identifier(let value):
            expr = try parseIdentifier(value)
        case .unit(let value):
            expr = try parseUnit(value)
        case .operator(let op):
            expr = try parseOperator(op)
        default:
            throw ParseError.unexpectedToken(token)
        }
        
        expr = try parseNext(expr: expr, isPow: isPow, isTimDiv: isTimDiv)
        
        return expr
    }
    
    func consume(_ token: Token) throws {
        guard let tok = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard token == tok else {
            throw ParseError.unexpectedToken(token)
        }
        consumeToken()
    }
    
    func parseIdentifier() throws -> String {
        guard let token = currentToken else {
            throw ParseError.unexpectedEOF
        }
        guard case .identifier(let name) = token else {
            throw ParseError.unexpectedToken(token)
        }
        consumeToken()
        return name
    }
    
    func parsePrototype() throws -> Prototype {
        let name = try parseIdentifier()
        let params = try parseCommaSeparated(parseIdentifier)
        return Prototype(name: name, params: params)
    }
    
    func parseCommaSeparated<TermType>(_ parseFn: () throws -> TermType) throws -> [TermType] {
        try consume(.leftParen)
        var vals = [TermType]()
        while let tok = currentToken, tok != .rightParen {
            let val = try parseFn()
            vals.append(val)
        }
        try consume(.rightParen)
        return vals
    }
}

// MARK: - Parse

private extension Parser {
    
    // MARK: Left paren
    
    func parseleftParen() throws -> Expr {
        var expr: Expr
        
        consumeToken()
        expr = try parseExpr()
        if case let .binary(l, op, r, _) = expr {
            expr = .binary(l, op, r, true)
        }
        try consume(.rightParen)
        
        return expr
    }
    
    // MARK: Number

    func parseNumber(_ number: Double) throws -> Expr {
        consumeToken()
        return .number(number)
    }
    
    // MARK: Identifier

    func parseIdentifier(_ value: String) throws -> Expr {
        consumeToken()
        
        var expr: Expr!
        let identifier = value.components(separatedBy: CharacterSet.letters.inverted).joined()

        for item in identifier.enumerated() {
            if expr == nil {
                expr = .variable(String(item.element))
            } else {
                expr = .binary(expr, .times, .variable(String(item.element)), false)
            }
        }
        if let number = Double(value.components(separatedBy: CharacterSet.letters).joined()) {
            expr = .binary(.number(number), .times, expr, true)
        }
        
        guard expr != nil else { throw ParseError.unexpectedEOF }
        return expr
    }
    
    // MARK: Unit

    func parseUnit(_ value: String) throws -> Expr {
        consumeToken()
        return .unit(value)
    }
    
    // MARK: Operator

    func parseOperator(_ op: BinaryOperator) throws -> Expr {
        guard let token = currentToken else { throw ParseError.unexpectedEOF }
        
        if op == .minus {
            consumeToken()
            let rhs = try parseExpr()
            return .binary(Expr.number(0.0), op, rhs, false)
        } else {
            throw ParseError.unexpectedToken(token)
        }
    }
    
    // MARK: Next

    func parseNext(expr: Expr, isPow: Bool, isTimDiv: Bool) throws -> Expr {
        var expr = expr
        
        // Divide
        if case .operator(let op)? = currentToken, (op == .divide || op == .times) {
            consumeToken()
            let rhs = try parseExpr(isTimDiv: true)
            expr = .binary(expr, op, rhs, false)
        }
        
        // Power
        if case .operator(let op)? = currentToken, op == .power {
            consumeToken()
            let rhs = try parseExpr(isPow: true)
            if case let .binary(l, o, r, inParen) = expr, (o == .times || o == .divide) {
                expr = .binary(l, o, .binary(r, op, rhs, false), inParen)
            } else {
                expr = .binary(expr, op, rhs, false)
            }
        }
        
//        // Operators
        if case .operator(let op)? = currentToken, !isPow, !isTimDiv {
            consumeToken()
            
            if op == .percent {
                return .binary(expr, .percent, .variable(""), false)
            }
            
            let rhs = try parseExpr()
            if case let .binary(l, o, r, inParen) = rhs {
                if o == .equals {
                    let expres = Expr.binary(expr, op, l, inParen)
                    expr = .binary(expres, o, r, false)
                    return expr
                }
            }
            expr = .binary(expr, op, rhs, false)
        }
        
        return expr
    }
}
