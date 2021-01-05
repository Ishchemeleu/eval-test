import Foundation

extension NSExpression {
    var value: Double {
        guard let num = self.expressionValue(with: nil, context: nil) as? Double else { return 0.0 }
        return num
    }
}
