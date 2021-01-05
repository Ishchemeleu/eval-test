import Foundation

public enum ExpressionComparisonError: Error {
    case notEqual
    case notSimplify
    case notEqualNotSimplify
    case incorrectDecimalsCount(Int)
    case wrongCase(String)
    case differentFractionFormats
    case differentDecimalFormats
    case differentPercentageFormats
    case differentSimpleExpressionFormats(String)
    case dividedByZero
    case other
}

public class File {
    private let nf = NumberFormatter()
    
    private(set) var externs = [Prototype]()
    private(set) var definitions = [Definition]()
    private(set) var expressions = [Expr]()
    private(set) var prototypeMap = [String: Prototype]()
    
    init() {
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
    }
    
    public var isFraction: Bool {
        let expr = expression()
        return expr.stringMatches(for: String.fractionRegex).count > 0
    }
    
    public var isDecimal: Bool {
        let expr = expression()
        return expr.stringMatches(for: String.decimalRegex).count > 0
    }
    
    public var isSimplifiedFormat: Result<Bool> {
        var isSimpl = Result.success(true)
        for expr in expressions {
            if case .success(_) = isSimpl {
                isSimpl = SimplifyEvaluator.isSimplifiedFormat(expr: expr)
            }
        }
        return isSimpl
    }
    
    public var isPercentage: Bool {
        let expr = expression()
        return expr.stringMatches(for: String.percentageRegex).count > 0
    }
    
    // simple expression (x=2, y>3)
    static func isSimpleExpression(file: File) -> Bool {
        if let expr = file.expressions.first, case let Expr.binary(a, _, c, _) = expr, case let Expr.variable(variable) = a, case let Expr.number(_) = c {
            return true
        }
        return false
    }
    
    static func getFormatOfSimpleExpression(file: File) -> String? {
        if let expr = file.expressions.first, case let Expr.binary(a, b, c, _) = expr, case let Expr.variable(variable) = a, case let Expr.number(_) = c {
            return variable + b.symbol
        }
        return nil
    }
    
    static func isComplexExpression(file: File) -> Bool {
        if file.expressions.count > 1 { return true }
        if let expr = file.expressions.first, case let Expr.binary(a, _, _, _) = expr, case let Expr.binary(_, _, _, _) = a {
            return true
        }
        return false
    }
  
    func prototype(name: String) -> Prototype? {
        return prototypeMap[name]
    }
    
    func addExpression(_ expression: Expr) {
        expressions.append(expression)
    }
    
    func addExtern(_ prototype: Prototype) {
        externs.append(prototype)
        prototypeMap[prototype.name] = prototype
    }
    
    func addDefinition(_ definition: Definition) {
        definitions.append(definition)
        prototypeMap[definition.prototype.name] = definition.prototype
    }
    
    public static func ==(lhs: File, rhs: File) -> Result<Bool> {
        let double = Double.random()
        
        //        // is complex expression (like "x+3=y")
        //        let lIsComplexExpression = isComplexExpression(file: lhs)
        //        let rIsComplexExpression = isComplexExpression(file: rhs)
        //
        //        if lIsComplexExpression {
        //            return .failure(ExpressionComparisonError.other)
        //        }
        //
        //        // is simple expression (like "x=2")
        //        let lIsSimpleExpression = isSimpleExpression(file: lhs)
        //        let rIsSimpleExpression = isSimpleExpression(file: rhs)
        //
        //        if lIsSimpleExpression && lIsSimpleExpression != rIsSimpleExpression && !rIsComplexExpression {
        //            if let expressionFormat = getFormatOfSimpleExpression(file: lhs) {
        //                return .failure(ExpressionComparisonError.differentSimpleExpressionFormats(expressionFormat))
        //            }
        //        } else if lIsSimpleExpression && lIsSimpleExpression == rIsSimpleExpression {
        //            if let lExpressionFormat = getFormatOfSimpleExpression(file: lhs), let rExpressionFormat = getFormatOfSimpleExpression(file: rhs),
        //                lExpressionFormat != rExpressionFormat {
        //                return .failure(ExpressionComparisonError.differentSimpleExpressionFormats(lExpressionFormat))
        //            }
        //        }
        
        
        if isDividedByZero(file: rhs) {
            return .failure(ExpressionComparisonError.dividedByZero)
        }
        
        let lIsFraction = lhs.isFraction
        let rIsFraction = rhs.isFraction
        
        let lIsPercentage = lhs.isPercentage
        let rIsPercentage = rhs.isPercentage
        
        let lIsDecimal = lhs.isDecimal
        let rIsDecimal = rhs.isDecimal
        
        let sameType = lIsFraction == rIsFraction && lIsDecimal == rIsDecimal && lIsPercentage == rIsPercentage
        
        if let lExpressionToConvert = lhs.expressions.first, let rExpressionToConvert = rhs.expressions.first {
            // convert to one type both answers
            if lIsFraction {
                if let convertedValue = convertFractionToDecimal(from: lExpressionToConvert) {
                    lhs.expressions = [convertedValue]
                }
            } else if lIsPercentage {
                if let convertedValue = convertPercentsToDecimal(from: lExpressionToConvert) {
                    lhs.expressions = [convertedValue]
                }
            }
            
            if rIsFraction {
                if let convertedValue = convertFractionToDecimal(from: rExpressionToConvert) {
                    rhs.expressions = [convertedValue]
                }
            } else if rIsPercentage {
                if let convertedValue = convertPercentsToDecimal(from: rExpressionToConvert) {
                    rhs.expressions = [convertedValue]
                }
            }
        }
        
        let isEqual = lhs.expressions == rhs.expressions
        let isEqualLowercase = (lhs.expressions == rhs.expressions ||
            lhs.result(for: double, lowercase: true) == rhs.result(for: double, lowercase: true))
        
        if !sameType && isEqual {
            if lIsDecimal && !rIsDecimal {
                return .failure(ExpressionComparisonError.differentDecimalFormats)
            } else if lIsPercentage && !rIsPercentage {
                return .failure(ExpressionComparisonError.differentPercentageFormats)
            } else if lIsFraction && !rIsFraction {
                return .failure(ExpressionComparisonError.differentFractionFormats)
            }
        }
        
        if !isEqual && isEqualLowercase {
            let lVars = getAllVariables(from: lhs.expressions.first)
            let rVars = getAllVariables(from: rhs.expressions.first)
            
            for lvar in lVars {
                for rvar in rVars {
                    if lvar != rvar && lvar.lowercased() == rvar.lowercased() {
                        return .failure(ExpressionComparisonError.wrongCase(lvar))
                    }
                }
            }
            
            return .failure(ExpressionComparisonError.other)
        } else {
            return isEqual ? .success(true) : .failure(ExpressionComparisonError.notEqual)
        }
    }
    
    public func output() {
        expressions.forEach { (expr) in print(expression()) }
    }
    
    /**
     Calculates the value of the parsed expression
     
     - returns: The value as a double.
     */
    public func result(for double: Double = 0.0, lowercase: Bool = false) -> Double {
        let expr = expression(for: double, lowercase: lowercase)
        let nsExpr = NSExpression(format: expr)
        return nsExpr.value
    }
    
    // MARK: Helper Methods
    
    /**
     Processes the expressions in the expressions array and creates a valid String for NSExpressions.
     
     - parameter double: The value which should be inserted for a identifier inside of the expression. (Default value: 0.0)
     
     - returns: A valid String which can be processed by NSExpressions.
     */
    private func expression(for double: Double = 0.0, lowercase: Bool = false) -> String {
        var string = ""
        for expr in expressions {
            switch expr {
            case .number(let number):
                string.append(nf.string(from: NSNumber(value: number)) ?? "")
            case .variable(let value):
                string.append(processVariable(value, with: double, lowercase: lowercase))
            case .binary(let left, let binary, let right, let inParen):
                string.append(processBinary(left: left,
                                            right: right,
                                            binary: binary,
                                            inParen: inParen,
                                            with: double,
                                            lowercase: lowercase))
            case .unit(let unit):
                string.append(processUnit(unit))
            }
        }
        if string == "" {
            string.append("0.0")
        }
        return string.replacingOccurrences(of: ",", with: "")
    }
    
    /**
     Processes a given expression and creates a valid String for NSExpressions.
     
     - parameter expr: The expression which should be processed.
     
     - parameter double: The value which should be inserted for a identifier inside of the expression. (Default value: 0.0)
     
     - returns: A valid String which can be processed by NSExpressions.
     */
    private func getExpr(_ expr: Expr, with d: Double, lowercase: Bool) -> String {
        var string = ""
        switch expr {
        case .number(let num):
            string.append(nf.string(from: NSNumber(value: num)) ?? "")
            break
        case .variable(let value):
            string.append(processVariable(value, with: d, lowercase: lowercase))
            break
        case .binary(let left, let binary, let right, let inParen):
            string.append(processBinary(left: left,
                                        right: right,
                                        binary: binary,
                                        inParen: inParen,
                                        with: d,
                                        lowercase: lowercase))
            break
        case .unit(let unit):
            string.append(processUnit(unit))
        }
        return string
    }
    
    /**
     Helper method to process a unit expression and create a valid String for NSExpressions.
     
     - parameter value: The value of the unit. For example: 15cm.
     
     - returns: A valid String which can be processed by NSExpressions.
     */
    private func processUnit(_ value: String) -> String {
        var string = ""
        guard let identif = value.stringMatches(for: String.letterRegex).first,
            let unitHash = UnitTypes(rawValue: identif)?.hashValue else { return "" }
        if let digits = value.stringMatches(for: String.numberRegex).first {
            string.append(digits)
            string.append("*\(unitHash)")
        } else {
            string.append("\(unitHash)")
        }
        return string
    }
    
    /**
     Helper method to process a binary expression (e.g. 5+5) and create a valid String for NSExpressions.
     
     - parameter left: The value of the left hand side of the expression.
     
     - parameter right: The value of the right hand side of the expression.
     
     - parameter binary: The binary operator of the expression.
     
     - parameter inParen: If the expression is in parens.
     
     - parameter d: The value which should be inserted for a identifier inside of the expression.
     
     - returns: A valid String which can be processed by NSExpressions.
     */
    private func processBinary(left: Expr, right: Expr,
                               binary: BinaryOperator,
                               inParen: Bool,
                               with d: Double,
                               lowercase: Bool) -> String {
        var string = ""
        if inParen {
            string.append("(")
        }
        if binary == .mod {
            string.append("modulus:by:(\(getExpr(left, with: d, lowercase: lowercase)),\(getExpr(right, with: d, lowercase: lowercase)))")
        } else if binary != .equals {
            string.append("\(getExpr(left, with: d, lowercase: lowercase))")
            string.append(binary.symbol)
            string.append("\(getExpr(right, with: d, lowercase: lowercase))")
        } else {
            string.append("\(getExpr(left, with: d, lowercase: lowercase))")
            string.append("-")
            string.append("(\(getExpr(right, with: d, lowercase: lowercase)))")
        }
        if inParen {
            string.append(")")
        }
        return string
    }
    
    
    /**
     Helper method to process a variable expression and create a valid String for NSExpressions.
     
     - parameter value: The value of the variable. For example: 5x.
     
     - parameter d: The value which should be inserted for the variable.
     
     - returns: A valid String which can be processed by NSExpressions.
     */
    private func processVariable(_ value: String, with d: Double, lowercase: Bool) -> String {
        var string = ""
        
        guard let `var` = value.stringMatches(for: String.letterRegex).first else { return "" }
        let variable = lowercase ? `var`.lowercased() : `var`
        
        let bitIntValue = Double(variable.utf16.reduce(0, +))
        if let digits = value.stringMatches(for: String.numberRegex).first {
            string.append(digits)
            string.append("*")
            if d != 0.0 {
                string.append("\(d*bitIntValue)")
            } else {
                string.append("\(Double.random()*bitIntValue)")
            }
        } else {
            if value.first == "-" {
                if d != 0.0 {
                    string.append("-\(d*bitIntValue)")
                } else {
                    string.append("-\(Double.random()*bitIntValue)")
                }
            } else {
                if d != 0.0 {
                    string.append("\(d*bitIntValue)")
                } else {
                    string.append("\(Double.random()*bitIntValue)")
                }
            }
        }
        return string
    }
    
    private static func getAllVariables(from expr: Expr?) -> [String] {
        guard let expr = expr else { return [] }
        
        var varibles: [String] = []
        switch expr {
        case .variable(let identifier):
            varibles.append(identifier)
        case .binary(let lexpr, _, let rexpr, _):
            varibles.append(contentsOf: getAllVariables(from: lexpr))
            varibles.append(contentsOf: getAllVariables(from: rexpr))
        default: break;
        }
        
        return varibles
    }
    
    private static func convertPercentsToDecimal(from expr: Expr) -> Expr? {
        guard case let .binary(lexpr,_,_,_) = expr else {return nil }
        guard case let .number(num) = lexpr else { return nil }
        return Expr.number(num/100)
    }
    
    private static func convertFractionToDecimal(from expr: Expr) -> Expr? {
        guard case let .binary(lexpr,_,rexpr,_) = expr else {return nil }
        guard case let .number(lNum) = lexpr,
            case let .number(rNum) = rexpr else { return nil }
        return Expr.number(lNum/rNum)
    }
    
    private static func isDividedByZero(file: File) -> Bool {
        for expr in file.expressions {
            if case let .binary(_,unit,rexpr,_) = expr,
                unit == .divide,
                case let .number(rNum) = rexpr,
                rNum == 0 { return true }
        }
        return false
    }
    
}
