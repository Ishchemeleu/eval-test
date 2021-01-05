//
//  GreatestCommonDiv.swift
//  Test
//
//  Created by Test on 13.07.2018.
//  Copyright © 2018 Radish AB. All rights reserved.
//

import Foundation

class GreatestCommonDiv {
    
    private typealias Rational = (num : Int, den : Int)
    
    static func commonDivision(numbers : [Double]) -> [Int] {
        let filteredNum = numbers.filter() { $0 != 0 }
        
        let rats = filteredNum.map { rationalApproximationOf($0) }
        let dividend = gcd(vector: rats.map() { $0.num })
        let divisor = gcd(vector: rats.map() { $0.den })
        
        var div:[Int] = []
        if dividend > 1 { div.append(dividend) }
        if divisor > 1 { div.append(divisor) }
        
        return div
    }
    
    // GCD of two numbers:
    private static func gcd(_ m: Int, _ n: Int) -> Int {
        var a = 0
        var b = max(m, n)
        var r = min(m, n)
        
        while r != 0 {
            a = b
            b = r
            r = a % b
        }
        return b
    }
    
    // GCD of a vector of numbers:
    private static func gcd(vector: [Int]) -> Int {
        return vector.reduce(0) { gcd($0, $1) }
    }
    
    private static func rationalApproximationOf(_ x0 : Double, withPrecision eps : Double = 1.0E-6) -> Rational {
        var x = x0
        var a = floor(x)
        var (h1, k1, h, k) = (1, 0, Int(a), 1)
        
        while x - a > eps * Double(k) * Double(k) {
            x = 1.0/(x - a)
            a = floor(x)
            (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
        }
        return (h, k)
    }
    
}
