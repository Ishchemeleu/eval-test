//
//  UnitEvaluator.swift
//  Test
//
//  Created by Test on 26.07.2018.
//  Copyright © 2018 Radish AB. All rights reserved.
//

import UIKit

public enum UnitConvertionError: Error {
    case numberMissing
    case unitMissing
    case incorrectUnit(String)
    case wrongUnit
    case wrongUnitCase(String)
    case unitMismatch
    case unsupportedIOSVersion
}

class UnitEvaluator {
    
    static func compare(lhs: String, rhs: String, completion: @escaping (Result<Bool>) -> Void) {
        
        let lhs = lhs.removeSpacesAndBrackets()
        let rhs = rhs.removeSpacesAndBrackets()
        
        // Check number is empty
        guard let lStringNumber = lhs.stringMatches(for: String.numberRegex).first,
            let rStringNumber = rhs.stringMatches(for: String.numberRegex).first,
            let lNumber = Double(lStringNumber),
            let rNumber = Double(rStringNumber)
            else {
                if lhs.stringMatches(for: String.numberRegex).isEmpty
                    && rhs.stringMatches(for: String.numberRegex).isEmpty {
                    completion(.success(true))
                } else {
                    completion(.failure(UnitConvertionError.numberMissing))
                }
                return
        }
        
        let lUnitString = lhs.dropFirst(lStringNumber.count)
        let rUnitString = rhs.dropFirst(rStringNumber.count)
        
        // Check is empty
        if (lStringNumber == rStringNumber) && (lUnitString.isEmpty || rUnitString.isEmpty) { completion(.failure(UnitConvertionError.unitMissing)); return }
        
        // Check is unit (is existed)
        let lResult = unit(with: String(lUnitString))
        let rResult = unit(with: String(rUnitString))
        
        guard case let .success(lUnit) = lResult, case let .success(rUnit) = rResult else {
            if case let .failure(error) = rResult {
                if case let .success(lUnit) = lResult, lNumber == rNumber {
                    completion(.failure(UnitConvertionError.unitMissing))
                    return
                }
                completion(.failure(error))
            }
            if case let .failure(error) = lResult {
                completion(.failure(error))
            }
            return
        }
        
        // Compare units (different groups)
        guard compareUnits(lhs: lUnit, rhs: rUnit) else {
            if lNumber == rNumber {
                completion(.failure(UnitConvertionError.unitMissing))
                return
            }
            completion(.failure(UnitConvertionError.unitMismatch))
            return
        }
        
        if #available(iOS 10.0, *) {
            let isEvaluate = lUnit.evaluateEquality(value: lNumber, unitToCompare: rUnit, valueToCompare: rNumber)
            if isEvaluate && lUnit.rawValue != rUnit.rawValue {
                completion(.failure(UnitConvertionError.incorrectUnit(lUnit.rawValue)))
            } else if !isEvaluate && lNumber == rNumber {
                completion(.failure(UnitConvertionError.unitMissing))
            } else {
                if !isEvaluate { completion(.success(isEvaluate)); return }
                // Check case unit
                let lResult = unit(with: String(lUnitString), allowCase: false)
                let rResult = unit(with: String(rUnitString), allowCase: false)
                
                if case let .failure(error) = lResult {
                    completion(.failure(error))
                } else if case let .failure(error) = rResult {
                    completion(.failure(error))
                } else {
                    if let isDoubleComparing = Evaluator().doubleComparing(lStringNumber, rStringNumber) { completion(isDoubleComparing); return }
                    completion(.success(isEvaluate))
                }
            }
        } else {
            completion(.failure(UnitConvertionError.unsupportedIOSVersion))
        }
    }
    
    private static func unit(with string: String, allowCase: Bool = true) -> Result<UnitTypes> {
        for caseType in UnitTypes.allCases() {
            let ltype = allowCase ? caseType.rawValue.lowercased() :  caseType.rawValue
            let rType = allowCase ? string.lowercased() : string
            if ltype == rType {
                return Result.success(caseType)
            } else if caseType.rawValue.lowercased() == string.lowercased() {
                return Result.failure(UnitConvertionError.wrongUnitCase(caseType.rawValue))
            }
        }
        return Result.failure(UnitConvertionError.wrongUnit)
    }
    
    private static func compareUnits(lhs: UnitTypes, rhs: UnitTypes) -> Bool {
        var units:[UnitTypes] = []
        switch lhs {
        case .millimeter, .centimeter, .decimeter, .meter, .kilometer:
            units = [.millimeter, .centimeter, .decimeter, .meter, .kilometer]
        case .milliliter, .litre, .megaLiter, .centiLiter, .deciLitre:
            units = [.milliliter, .litre, .megaLiter, .centiLiter, .deciLitre]
        case .squareMillimeter, .squareCentimeter, .squareDecimeter, .squareMeter, .squareKilometer:
            units = [.squareMillimeter, .squareCentimeter, .squareDecimeter, .squareMeter, .squareKilometer]
        case .cubicMillimeter, .cubicCentimeter, .cubicDecimeter, .cubicMeter:
            units = [.cubicMillimeter, .cubicCentimeter, .cubicDecimeter, .cubicMeter]
        case .milligram, .gram, .hectogram, .kilogram, .tonne:
            units = [.milligram, .gram, .hectogram, .kilogram, .tonne]
        case .second, .minute, .hour:
            units = [.second, .minute, .hour]
        case .degreeCelcius, .degreeFahrenheit, .degreeKelvin:
            units = [.degreeCelcius, .degreeFahrenheit, .degreeKelvin]
        case .degree:
            units = [.degree]
        case .swedishCrown:
            units = [.swedishCrown]
        case .perMille:
            units = [.perMille]
        }
        
        return units.contains(rhs)
    }
    
}
