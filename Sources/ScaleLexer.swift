//
//  ScaleEvaluator.swift
//  Test
//
//  Created by Test on 08.08.2018.
//  Copyright © 2018 Radish AB. All rights reserved.
//

public enum AnswerScaleError: Error {
    case parserError
}

public class ScaleLexer {
   
    static let scalePrefix = "scale="
    
    private let input: String

    public init(input: String) {
        self.input = input
    }
    
    public var isScale: Bool { return input.hasPrefix(ScaleLexer.scalePrefix) }
    
    public func lex() -> [Token] {
        var input = self.input
        if input.hasPrefix(TimeLexer.timePrefix) {
            input = String(self.input.dropFirst(ScaleLexer.scalePrefix.count))
        }
        
        let values = input.components(separatedBy: ":").compactMap {
            Double($0.digits)
        }
        return [.number(values.reduce(0, { (result, number) -> Double in
            if result == 0 { return number }
            return result/number
        })), .semicolon]
    }
    
}
