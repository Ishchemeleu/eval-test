//
//  DateLexer.swift
//  Test
//
//  Created by Test on 08.08.2018.
//  Copyright © 2018 Radish AB. All rights reserved.
//

import Foundation

public enum AnswerTimeError: Error {
    case wrongFormat
}

public class TimeLexer {

    static let timePrefix = "time="
    private let formats = ["HH:mm", "H:mm", "hh.mm a", "h.mm a"]
    
    private let input: String
    
    public init(input: String) {
        self.input = input
    }
    
    public var isTime: Bool { return input.hasPrefix(TimeLexer.timePrefix) }
    
    public func lex() -> Date? {
        var input = self.input
        if input.hasPrefix(TimeLexer.timePrefix) {
            input = String(self.input.dropFirst(TimeLexer.timePrefix.count))
        }
            
        let dateFormatter = DateFormatter()
        let date = formats.reduce(nil) { (result, dateFormat) -> Date? in
            if result != nil { return result }
            dateFormatter.dateFormat = dateFormat
            return dateFormatter.date(from: input)
        }
        
        return date
    }
    
}
