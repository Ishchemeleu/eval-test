import Foundation

public struct Evaluator {
    
    private let currentVersion = "0.2.22"
    
    public init() {}
    
    public func version() -> String {
        return "Expression Evaluator Version: \(self.currentVersion)"
    }
    
    public func evaluate(samples: [String]) throws {
        for sample in samples {
            try self.evaluate(sample: sample)
        }
    }
    
    public func calculate(samples: [String]) throws {
        for sample in samples {
            try self.calculate(sample: sample)
        }
    }
    
    public func evaluate(sample: String) throws {
        let file = try self.getFile(by: sample)
        file.output()
    }
    
    public func calculate(sample: String) throws {
        let file = try self.getFile(by: sample)
        print(file.result())
    }
    
    /**
     Compares two units represented as strings.
     
     - returns: A boolean whether the expression are the same or not.
     */
    public func compareUnits(_ lhs: String, _ rhs: String, completion: @escaping (Result<Bool>) -> Void)  {
        UnitEvaluator.compare(lhs: lhs, rhs: rhs) { (result) in
            completion(result)
        }
    }
    
    /**
     Compares two expressions represented as strings.
     
     - returns: A boolean whether the expression are the same or not.
     */
    public func compare(_ lhs: String, _ rhs: String,
                        checkSimplifyExpr: Bool = true,
                        smartEvaluation: Bool = false,
                        completion: @escaping (Result<Bool>) -> Void) {
        var lhs = lhs.removeSpacesAndBrackets()
        var rhs = rhs.removeSpacesAndBrackets()
        
        if !smartEvaluation { completion(.success(lhs == rhs)); return }
        
        lhs = lhs.replacingOccurrences(of: ",", with: ".")
        rhs = rhs.replacingOccurrences(of: ",", with: ".")
        
        do {
            if let isEqual = timeEvaluator(lhs, rhs) { completion(isEqual); return }
            if let isEqual = scaleEvaluator(lhs, rhs) { completion(isEqual); return }
            
            if let isDoubleComparing = doubleComparing(lhs, rhs) { completion(isDoubleComparing); return }

            let file = try self.getFile(by: lhs)
            let file2 = try self.getFile(by: rhs)
            file.output()
            file2.output()
            
            if let lExpr = file.expressions.first, isMissingUnit(expr: lExpr),
                let rExpr = file2.expressions.first, isMissingUnit(expr: rExpr) {
                
                let compare = self.compare(file, file2)
                if  case let .success(isSuccess) = compare, isSuccess {
                    if checkSimplifyExpr && lhs != rhs {
                        let isSimpl = try isSimplifiedFormat(rhs)
                        if case .failure(_) = isSimpl { completion(isSimpl); return }
                    }
                    completion(compare)
                } else {
                    completion(compare)
                }
            } else {
                compareUnits(lhs, rhs, completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /**
     Evaluate string and check is value in the shortest possible format
     
     - returns: A boolean whether the expression are the simplified or not.
     */
    public func isSimplifiedFormat(_ value: String) throws -> Result<Bool> {
        let file = try self.getFile(by: value)
        file.output()
        return isSimplifiedFormat(file)
    }
    
    /**
     Compares two files and whether the expressions they hold are the same.
     
     - returns: A boolean whether the expression are the same or not.
     */
    public func compare(_ lhs: File, _ rhs: File) -> Result<Bool> {
        return lhs == rhs
    }
    
    /**
     Evaluate file and check is value in the shortest possible format
     
     - returns: A boolean whether the expression are the simplified or not.
     */
    public func isSimplifiedFormat(_ value: File) -> Result<Bool> {
        return value.isSimplifiedFormat
    }
    
    /**
     Helper method to create a File out of a String.
     
     - parameter sample: A expression represented as String. For example: 5x + 10.
     
     - returns: A File which holds the expression.
     */
    private func getFile(by sample: String) throws -> File {
        let toks = Lexer(input: "\(sample.removeSpacesAndBrackets());").lex()
        let file = try Parser(tokens: toks).parseFile()
        return file
    }
    
    private func isMissingUnit(expr: Expr) -> Bool {
        var unitMissing = true
        switch expr {
        case .number(_), .variable(_):
            unitMissing = unitMissing ? true : unitMissing
        case .unit(_):
            unitMissing = false
        case .binary(let lexpr, _, let rexpr, _):
            unitMissing = isMissingUnit(expr: lexpr)
            unitMissing = unitMissing ? isMissingUnit(expr: rexpr) : false
        }
        return unitMissing
    }
    
    private func timeEvaluator(_ lhs: String, _ rhs: String) -> Result<Bool>? {
        let timeLhs = TimeLexer(input: lhs)
        let timeRhs = TimeLexer(input: rhs)
        
        if timeLhs.isTime {
            let timeL = timeLhs.lex()
            let timeR = timeRhs.lex()
            if timeL == nil || timeR == nil {
                return .failure(AnswerTimeError.wrongFormat)
            } else {
                return .success(timeL == timeR)
            }
        }
        return nil
    }
    
    private func scaleEvaluator(_ lhs: String, _ rhs: String) -> Result<Bool>? {
        let scaleLhs = ScaleLexer(input: lhs)
        let scaleRhs = ScaleLexer(input: rhs)
        
        if scaleLhs.isScale {
            do {
                let fileL = try Parser(tokens: scaleLhs.lex()).parseFile()
                let fileR = try Parser(tokens: scaleRhs.lex()).parseFile()
                return compare(fileL, fileR)
            } catch {
                return .failure(AnswerScaleError.parserError)
            }
        }
        return nil
    }
    
    func doubleComparing(_ lhs: String, _ rhs: String) -> Result<Bool>? {
        
        let lhsSet = lhs.components(separatedBy: ".")
        let rhsSet = rhs.components(separatedBy: ".")

        if (lhsSet.count == 2 && rhsSet.count == 2),
            let intLhs = Int(lhsSet[0]), let intRhs = Int(rhsSet[0]),
            let decimalLhs = Int(lhsSet[1]), let decimalRhs = Int(rhsSet[1])
        {
            let decimalLhsString = lhsSet[1]
            let decimalRhsString = rhsSet[1]
            
            let decimalLhsCount = decimalLhsString.count
            let decimalRhsCount = decimalRhsString.count
            
            if Double(lhs) != Double(rhs) {
                return .failure(ExpressionComparisonError.notEqual)
            }
        }
        return nil
    }
}
