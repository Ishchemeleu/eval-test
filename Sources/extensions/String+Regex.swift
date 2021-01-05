import Foundation

extension String {
    
    static var numberRegex: String {
        return "-?\\d*\\.{0,1}\\d+"
    }
    
    static var letterRegex: String {
        return "[a-zA-Z\\%]+"
    }
    
    static var percentageRegex: String {
        return "[\\%]+"
    }
    
    static var decimalRegex: String {
        return "[\\.,]+"
    }
    
    static var fractionRegex: String {
        return "[\\/]+"
    }
    
    func stringMatches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.compactMap {
                Range($0.range, in: self).map { String(self[$0]) }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func removeSpacesAndBrackets() -> String {
        return components(separatedBy: .whitespaces)
            .joined()
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
    }
    
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}

