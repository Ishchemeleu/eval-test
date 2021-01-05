import Foundation

extension Double {
    
    private static var max: Double {
        return 100.0
    }
    
    private static var min: Double {
        return 1.0
    }
    
    public static func random(in range: Range<Double>) -> Double {
        let ranDoub = (Double(arc4random()) / 0xFFFFFFFF) * (range.upperBound - range.lowerBound) + range.lowerBound
        let num = NSNumber(value: ranDoub)
        let numFormatter = NumberFormatter()
        numFormatter.maximumFractionDigits = 3
        let doubStr = numFormatter.string(from: num) ?? ""
        let doub = Double(doubStr.replacingOccurrences(of: ",", with: ".")) ?? min
        return doub
    }
    
    public static func random() -> Double {
        return Double.random(in: min..<max)
    }
}
