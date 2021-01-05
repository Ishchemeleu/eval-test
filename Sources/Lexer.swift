import Foundation

public class Lexer {
    var input: String
    var index: String.Index
    
    private var withoutUnit: Bool
    
    private var units: [String] = UnitTypes.allCases().compactMap { (type) -> String? in
        return type.rawValue
    }
    
    private let unitsCharacters = UnitTypes.allCases().reduce([]) { (set, type) -> Set<Character> in
        var set = set
        type.rawValue.forEach({ (char) in set.insert(char) })
        return set
    }
    
    public init(input: String, withoutUnit: Bool = false) {
        self.input = input
        self.index = input.startIndex
        self.withoutUnit = withoutUnit
        
        var inputStr = ""
        input.forEach { (char) in
            if char == "(", let last = inputStr.last, !isOperator(last) {
                inputStr += BinaryOperator.times.rawValue
            }
            inputStr += String(char)
            
            if !isOperator(char), let last = inputStr.last, last == ")" {
                inputStr += BinaryOperator.times.rawValue
            }
        }
        self.input = inputStr
    }
    
    var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }
    
    var lastChar: Character? {
        return index > input.startIndex ? input[input.index(index, offsetBy: -1)] : nil
    }
    
    func advanceIndex() {
        input.formIndex(after: &index)
    }
    
    /**
     Checks if the current character at index is a number or identifier.
     
     - returns: A number represented as String or a identifier as String.
     */
    func readIdentifierOrNumber() -> String {
        var str = ""
        while let char = currentChar, char.isAlphanumeric || char == "." || char == "," ||
            (withoutUnit ? false : unitsCharacters.reduce(false, { (result, character) -> Bool in return result ? result : character == char })) {
            str.append(char)
            advanceIndex()
        }
        return str
    }
    
    /**
     Creates a Token from the input at the current index.
     
     - returns: A Token such as number or operator or nil if there is no token at index.
     */
    func advanceToNextToken() -> [Token]? {
        while let char = currentChar, char.isSpace {
            advanceIndex()
        }
        
        guard let char = currentChar else {
            return nil
        }
        
        if isNegative(char) {
            advanceIndex()
            guard let nextChar = currentChar else {
                return nil
            }
            var charStr = ""
            if nextChar.isAlphanumeric {
                let str = readIdentifierOrNumber()
                charStr.append(str)
            }
            let str = "\(char)\(charStr)"
            if let dblVal = Double(str) {
                return [.number(dblVal)]
            } else {
                return [.identifier(str)]
            }
        }
        
        let singleTokMapping: [String: Token] = [
            "(": .leftParen,
            ")": .rightParen,
            ";": .semicolon,
            "+": .operator(.plus),
            "-": .operator(.minus),
            "*": .operator(.times),
            "/": .operator(.divide),
            "=": .operator(.equals),
            "^": .operator(.power),
            "×": .operator(.times),
            "%": .operator(.percent)
        ]
        
        if char.isAlphanumeric ||
            (withoutUnit ? false : unitsCharacters.reduce(false, { (result, character) -> Bool in return result ? result : character == char})) {
            let str = readIdentifierOrNumber()
                        
            let numFormatter = NumberFormatter()
            numFormatter.locale = Locale(identifier: "en_US")
            let num = numFormatter.number(from: str)
            
            if let dblVal = num?.doubleValue {
                return [.number(dblVal)]
            }
            
            let stringNumber = str.stringMatches(for: String.numberRegex).first
            let unitString = str.dropFirst(stringNumber?.count ?? 0)
            
            let numbers = str.stringMatches(for: String.numberRegex)
            if str.contains(BinaryOperator.mod.rawValue), numbers.count > 0 {
                return [.number(Double(numbers[0]) ?? 0), .operator(.mod),.number(Double(numbers[1]) ?? 0)]
            }
            
            let isUnit = units.reduce(false, { (result, unit) -> Bool in
                let isEqual = unitString == unit
                return result ? result : isEqual
            })
            
            if withoutUnit {
                if str.stringMatches(for: String.letterRegex).first != nil {
                    return [.identifier(str)]
                }
            } else {
                if isUnit {
                    return [.unit(str)]
                } else  {
                    return Lexer(input: str, withoutUnit: true).lex()
                }
            }
        }
        
        if let tok = singleTokMapping[String(char)] {
            advanceIndex()
            return [tok]
        }
        
        return nil
    }

    func isNegative(_ char: Character) -> Bool {
        return (index == input.startIndex && (char == "+" || char == "-")) || lastChar == "(" && (char == "+" || char == "-")
    }
    
    public func lex() -> [Token] {
        var toks = [Token]()
        while let toksNext = advanceToNextToken() {
            toks.append(contentsOf: toksNext)
        }
        return toks
    }
    
    private func isOperator(_ char: Character) -> Bool {
        let singleTokMapping: [String] = ["+", "-","*", "/", "=", "^", "×", "%"]
        return singleTokMapping.reduce(false) { (result, op) -> Bool in
            return result ? result : (op == String(char))
        }
    }
}
