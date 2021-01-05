//
//  SimplifyEvaluator.swift
//  Test
//
//  Created by Test on 13.07.2018.
//  Copyright © 2018 Radish AB. All rights reserved.
//

import Foundation

public enum SimplifyError: Error {
    case wrong
    case commonDiv(Int)
    case reoccurringVariable(String)
    
    static func !=(lhs: SimplifyError, rhs: SimplifyError) -> Bool {
        switch (lhs, rhs) {
        case (.wrong, .wrong), (.commonDiv(_), .commonDiv(_)), (.reoccurringVariable(_), .reoccurringVariable(_)):
            return false
        default:
            return true
        }
    }
}

extension String: Error {}
extension Array where Element == TokenValueCounter {
    var constants: Int {
        return self.reduce(0, { (result, counter) -> Int in
            return result + counter.constants.count
        })
    }
    
    static func ===(lhs: [TokenValueCounter], rhs: [TokenValueCounter]) -> Bool {
        return lhs.reduce(true, { (result, lToken) -> Bool in
            if !result { return result }
            return rhs.reduce(false, { (result, rToken) -> Bool in
                if result { return result }
                
                return lToken === rToken
            })
        })
    }
    
    static func compare(lhs: [TokenValueCounter]?, rhs: [TokenValueCounter]?) -> Bool {
        if let lhs = lhs, let rhs = rhs {
            return lhs === rhs
        } else if lhs == nil && rhs == nil {
            return true
        } else {
            return false
        }
    }
}
//MARK: - TokenValueCounter

struct TokenValueCounter {
    
    typealias ConstantsType = (constant: Double, powers: [TokenValueCounter]?)
    enum TokenValueType {
        case number
        case identifier(String)
        
        static func ==(lhs: TokenValueType, rhs: TokenValueType) -> Bool {
            switch (lhs, rhs) {
            case (.number, .number):
                return true
            case (.identifier(let lhs), .identifier(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }
    
    let type: TokenValueType
    private(set) var constants: [Double]
    private(set) var divides: [TokenValueCounter]?
    private(set) var powers: [TokenValueCounter]?
    
    init(type: TokenValueType, constants: [Double], divides: [TokenValueCounter]? = nil) {
        self.type = type
        self.constants = constants
        self.divides = divides
    }
    
    mutating func addConstant(_ value: Double) {
        constants.append(value)
    }
    
    mutating func addConstants(_ values: [Double]) {
        constants.append(contentsOf: values)
    }
    
    mutating func removeConstants() {
        constants = []
    }
    
    mutating func addPowers(_ values: [TokenValueCounter]) {
        if powers == nil { powers = [] }
        powers?.append(contentsOf: values)
    }
    
    mutating func removePowers() {
        powers = nil
    }
    
    mutating func addDivides(_ values: [TokenValueCounter]) {
        if divides == nil { divides = [] }
        divides?.append(contentsOf: values)
    }
    
    mutating func removeDivides() {
        divides = nil
    }
    
    static func ==(lhs: TokenValueCounter, rhs: TokenValueCounter) -> Bool {
        return lhs.type == rhs.type
    }
    
    static func ===(lhs: TokenValueCounter, rhs: TokenValueCounter) -> Bool {
        if let tokenPowers = lhs.powers, let counterPowers = rhs.powers, !(tokenPowers === counterPowers) {
            return false
        }
        
        return TokenValueCounter.compareBase(lhs:lhs, rhs:rhs)
    }
    
    static func compareBase(lhs: TokenValueCounter, rhs: TokenValueCounter) -> Bool {
        if let tokenDivides = lhs.divides, let counterDivides = rhs.divides, !(tokenDivides === counterDivides) {
            return false
        }
        let thisSet = Set(lhs.constants)
        let otherSet = Set(rhs.constants)
        
        return (thisSet.symmetricDifference(otherSet).count == 0 && lhs.type == rhs.type)
    }
    
}

//MARK: - SimplifyEvaluator

class SimplifyEvaluator {
    
    private let expression: Expr
    
    static func isSimplifiedFormat(expr: Expr) -> Result<Bool> {
        let evaluator = SimplifyEvaluator(expression: expr)
        
        do {
            let counters = try evaluator.processExpr(evaluator.expression)
            
            let uniqueVariables = evaluator.uniqueVariables(counters)
            let comonDiv = evaluator.haveComonDiv(counters)
            
            if case .success(_) = uniqueVariables, case  .success(_) = comonDiv {
                return .success(true)
            }
            if case let .failure(error) = uniqueVariables, let simplError = error as? SimplifyError,
                simplError != .wrong {
                return uniqueVariables
            }
            if case let .failure(error) = comonDiv, let simplError = error as? SimplifyError,
                simplError != .wrong {
                return comonDiv
            }
            
            return .failure(SimplifyError.wrong)
        } catch {
            print(error)
            return .failure(SimplifyError.wrong)
        }
    }
    
    private init(expression: Expr) {
        self.expression = expression
    }
    
    private func uniqueVariables(_ counters: [TokenValueCounter]) -> Result<Bool> {
        let uniqueCounter = counters.reduce(.success(true)) { (result, counter) -> Result<Bool> in
            if case .failure(_) = result { return result }
            
            let divUnique = uniqueVariables(counter.divides ?? [])
            if case .failure(_) = divUnique { return divUnique }
            
            if counter.constants.count <= 1 {
                return .success(true)
            } else {
                if case let .identifier(id) = counter.type {
                    return .failure(SimplifyError.reoccurringVariable(id))
                } else {
                    return .failure(SimplifyError.wrong)
                }
            }
        }
        return uniqueCounter
    }
    
    private func haveComonDiv(_ counters: [TokenValueCounter]) -> Result<Bool> {
        
        let constants = counters.compactMap { (counter) -> Double? in
            return counter.constants.first ?? 1
        }
        
        let commonDiv = GreatestCommonDiv.commonDivision(numbers: constants)
        if constants.count > 1, let first = commonDiv.first {
            return .failure(SimplifyError.commonDiv(first))
        }
        
        let haveCommonDivDenNum = counters.reduce(false) { (result, token) -> Bool in
            if let denominator = token.divides {
                let numerator = token.constants
                let denominator = denominator.reduce([]) { (result, counter) -> [Double] in return result + counter.constants }
                return result ? result : GreatestCommonDiv.commonDivision(numbers: numerator + denominator).count > 0
            }
            return result
        }
        let haveCommonDiv = counters.reduce(false) { (result, token) -> Bool in
            return counters.reduce(result, { (result, counter) -> Bool in
                if token === counter {
                    return result
                } else {
                    guard let tokenDivides = token.divides, let counterDivides = counter.divides else { return false }
                    return result ? result : tokenDivides === counterDivides
                }
            })
        }
        let haveCommonDivDenIden = counters.reduce(false) { (result, token) -> Bool in
            if case let .identifier(id) = token.type, !result,
                let denominator = token.divides, denominator.count == 1 {
                
                //search coomon character
                return denominator.reduce(false, { (result, denTok) -> Bool in
                    if case let .identifier(denId) = denTok.type, !result {
                        let max = denId.count > id.count ? denId : id
                        let min = denId.count <= id.count ? denId : id
                        
                        return max.reduce(false, { (result, characterMax) -> Bool in
                            return min.reduce(result, { (result, characterMin) -> Bool in
                                if result { return result }
                                return characterMax == characterMin
                            })
                        })
                        
                    }
                    return result
                })
            }
            return result
        }
        let havePow = counters.reduce(false) { (result, token) -> Bool in
            if !result, let powers = token.powers, powers.count == 1, let first = powers.first, first.type == .number,
                token.type == .number {
                return true
            }
            return result
        }
        
        if haveCommonDiv || haveCommonDivDenNum || haveCommonDivDenIden || havePow {
            return .failure(SimplifyError.wrong)
        } else {
            return .success(true)
        }
    }
    
    // Separate all values to TokenValueCounter who containts type(number or variables with identifier) and his constans
    // for example 2x + 3x + 4 = 0 it is TokenValueCounter(type .identifier("x") and constants(2,3)) and TokenValueCounter(type .number and constants(0,4))
    private func processExpr(_ expr: Expr) throws -> [TokenValueCounter] {
        var counters: [TokenValueCounter] = []
        
        switch expr {
        case .number(let num):
            return [TokenValueCounter(type: .number, constants: [num])]
        case .variable(let value):
            return [TokenValueCounter(type: .identifier(value), constants: [1])]
        case .unit(_):
            throw "Units not simplify"
        case .binary(let lexpr, let op, let rexpr, _):
            let lTokens = try processExpr(lexpr)
            let rTokens = try processExpr(rexpr)
            
            let tokens = processOperatos(lTokens: lTokens, op: op, rTokens: rTokens)
            counters = checkCounters(in: tokens, to: counters)
        }
        return counters
    }
    
    private func processOperatos(lTokens: [TokenValueCounter], op: BinaryOperator, rTokens: [TokenValueCounter]) -> [TokenValueCounter] {
        var counters: [TokenValueCounter] = []
        
        switch op {
        case .equals, .plus, .minus, .percent:
            counters = checkCounters(in: lTokens, to: counters)
            counters = checkCounters(in: rTokens, to: counters)
        case .times:
            counters = checkTimesCounters(in: lTokens, to: counters)
            counters = checkTimesCounters(in: rTokens, to: counters)
        case .divide, .mod:
            counters = checkDivideCounters(in: lTokens, to: rTokens)
        case .power:
            counters = checkPowerCounters(in: lTokens, to: rTokens)
        }
        
        return counters
    }
    
    //MARK: - Equal, plus, minus
    
    private func checkCounters(in inCounters: [TokenValueCounter], to toCounters: [TokenValueCounter]) -> [TokenValueCounter] {
        var toCounters = toCounters
        
        inCounters.forEach { (inCounter) in
            var inCounter = inCounter
            if let index = toCounters.index(where: { $0.type == inCounter.type }) {
                let toCounter = toCounters[index]
                
                //Check common denominator
                let isCommonDen = toCounter.divides != nil && inCounter.divides != nil && inCounter.divides! === toCounter.divides!
                let isDenNil = toCounter.divides == nil && toCounter.divides == nil
                
                let isCommonPow = toCounter.powers != nil && inCounter.powers != nil && inCounter.powers! === toCounter.powers!
                let isPowNil = toCounter.powers == nil && toCounter.powers == nil
                
                if (isCommonDen || isDenNil) &&
                    ((isCommonPow || isPowNil) && (inCounter.type == toCounter.type) && Array.compare(lhs: inCounter.powers, rhs: toCounter.powers)) {
                    toCounters.remove(at: index)
                    inCounter.addConstants(toCounter.constants)
                }
                
            }
            
            toCounters.append(inCounter)
        }
        
        return toCounters
    }
    
    //MARK: - Times
    
    private func checkTimesCounters(in inCounters: [TokenValueCounter], to toCounters: [TokenValueCounter]) -> [TokenValueCounter] {
        var toCounters = toCounters
        var powCounters: [TokenValueCounter] = []
        
        var inCounters = inCounters.compactMap { (inCounter) -> TokenValueCounter? in
            var inCounter = inCounter
            
            toCounters.enumerated().forEach({ (toCounter) in
                // Pow
                if  (inCounter.powers != nil || toCounter.element.powers != nil) {
                    inCounter = timesPowsConstants(in: inCounter, to: toCounter.element)
                } else if inCounter.powers != nil || inCounter.powers != nil {
                    powCounters.append(toCounter.element)
                } else {
                    // Times
                    switch (inCounter.type, toCounter.element.type) {
                    case (.number, .number):
                        let to = toCounter.element
                        toCounters.remove(at: toCounter.offset)
                        
                        inCounter.addConstants(to.constants)
                    case (.identifier(let rId), .number), (.number, .identifier(let rId)):
                        inCounter = TokenValueCounter(type: .identifier(rId),
                                                      constants: appendTimesConstants(inCounter.constants, toCounter.element.constants, isRemove: inCounters.count > 1))
                    case (.identifier(let lId), .identifier(let rId)):
                        inCounter = TokenValueCounter(type: .identifier(lId + rId),
                                                      constants: appendTimesConstants(inCounter.constants, toCounter.element.constants))
                    }
                    
                    let den = processOperatos(lTokens: inCounter.divides ?? [], op: .times, rTokens: toCounter.element.divides ?? [])
                    if den.count > 0 {
                        inCounter.removeDivides()
                        inCounter.addDivides(den)
                    }
                }
            })
            return inCounter
        }
        
        inCounters.append(contentsOf: powCounters)
        return inCounters
    }
    
    private func appendTimesConstants(_ lhs: [Double], _ rhs: [Double], isRemove: Bool = false) -> [Double] {
        var timesConstants:[Double] = []
        if !(lhs.count == 1 && lhs.first == 1) || isRemove {
            timesConstants.append(contentsOf: lhs)
        }
        if !(rhs.count == 1 && rhs.first == 1) || isRemove {
            timesConstants.append(contentsOf: rhs)
        }
        return timesConstants
    }
    
    private func timesPowsConstants(in inCounter: TokenValueCounter, to toCounter: TokenValueCounter) -> TokenValueCounter {
        var inCounter = inCounter
        var toCounter = toCounter
        
        if inCounter.type == .number && inCounter.powers == nil {
            toCounter.removeConstants()
            toCounter.addConstants(appendTimesConstants(inCounter.constants, toCounter.constants))
            inCounter = toCounter
        } else if toCounter.type == .number && toCounter.powers == nil {
            inCounter.removeConstants()
            inCounter.addConstants(appendTimesConstants(inCounter.constants, toCounter.constants))
        } else if TokenValueCounter.compareBase(lhs:inCounter, rhs:toCounter) {
            let token = TokenValueCounter(type: .number, constants: [1])
            inCounter.removePowers()
            let rTokens = (inCounter.powers == nil && toCounter.powers == nil) ? [] : toCounter.powers ?? [token]
            inCounter.addPowers(processOperatos(lTokens: inCounter.powers ?? [token],
                                                op: .plus,
                                                rTokens: rTokens))
        }
        return inCounter
    }
    
    //MARK: - Power
    
    private func checkPowerCounters(in inCounters: [TokenValueCounter], to toCounters: [TokenValueCounter]) -> [TokenValueCounter] {
        let inCounters = inCounters.compactMap { (inCounter) -> TokenValueCounter? in
            var inCounter = inCounter
            inCounter.addPowers(toCounters)
            return inCounter
        }
        
        return inCounters
    }
    
    //MARK: - Divide
    
    private func checkDivideCounters(in inCounters: [TokenValueCounter], to toCounters: [TokenValueCounter]) -> [TokenValueCounter] {
        if inCounters === toCounters { return inCounters + toCounters }
        let inCounters = inCounters.compactMap { (inCounter) -> TokenValueCounter? in
            var inCounter = inCounter
            inCounter.addDivides(toCounters)
            return inCounter
        }
        return inCounters
    }
}
