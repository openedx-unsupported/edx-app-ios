import Foundation

extension String {

    ///
    /// Returns a copy of the current `String` where every HTML entity is replaced with the matching
    /// Unicode character.
    ///
    /// ### Examples
    ///
    /// | String | Result | Format |
    /// |--------|--------|--------|
    /// | `&amp;` | `&` | Keyword entity |
    /// | `&#931;` | `Σ` | Decimal entity |
    /// | `&#x10d;` | `č` | Hexadecimal entity |
    /// | `&#127482;&#127480;` | `🇺🇸` | Combined decimal entities (extented grapheme cluster) |
    /// | `a` | `a` | Not an entity |
    /// | `&` | `&` | Not an entity |
    ///
    
    
    public var decodingHTMLEntities: String {
        var encodedString = self
        var startPosition = encodedString.startIndex
        
        while let matchingRegexRange = encodedString.range(of: "(&#?[a-zA-Z0-9]+;)", options: .regularExpression, range: startPosition ..< encodedString.endIndex, locale: nil) {
            let encodedText = encodedString[matchingRegexRange.lowerBound ..< matchingRegexRange.upperBound]
            let decodedText = encodedText.removingHTMLEntities
            if  decodedText != encodedText {
                encodedString.replaceSubrange(matchingRegexRange.lowerBound ..< matchingRegexRange.upperBound, with: decodedText)
                startPosition = matchingRegexRange.lowerBound
            }
            else {
                startPosition = matchingRegexRange.upperBound
            }
        }
        return encodedString
    }

    private var removingHTMLEntities: String {
        guard contains("&") else {
            return self
        }

        var result = ""
        var cursorPosition = startIndex

        while let delimiterRange = range(of: "&", range: cursorPosition ..< endIndex) {

            // Avoid unnecessary operations
            let head = self[cursorPosition ..< delimiterRange.lowerBound]
            result += head

            guard let semicolonRange = range(of: ";", range: delimiterRange.upperBound ..< endIndex) else {
                result += "&"
                cursorPosition = delimiterRange.upperBound
                break
            }

            let escapableContent = self[delimiterRange.upperBound ..< semicolonRange.lowerBound]
            let escapableContentString = String(escapableContent)
            let replacementString: String

            if (escapableContentString?.hasPrefix("#")) ?? false {

                guard let unescapedNumber = escapableContentString?.unescapeAsNumber else {
                    result += self[delimiterRange.lowerBound ..< semicolonRange.upperBound]
                    cursorPosition = semicolonRange.upperBound
                    continue
                }

                replacementString = unescapedNumber

            } else {

                guard let contentString = escapableContentString, let unescapedCharacter = HTMLUnescapingTable[contentString] else {
                    result += self[delimiterRange.lowerBound ..< semicolonRange.upperBound]
                    cursorPosition = semicolonRange.upperBound
                    continue
                }

                replacementString = unescapedCharacter

            }

            result += replacementString
            cursorPosition = semicolonRange.upperBound

        }

        // Append unprocessed data, if unprocessed data there is
        let tail = self[cursorPosition ..< endIndex]
        result += tail

        return result
    }

    private var unescapeAsNumber: String? {
        let isHexadecimal = hasPrefix("#X") || hasPrefix("#x")
        let radix = isHexadecimal ? 16 : 10

        let numberStartIndex = index(startIndex, offsetBy: isHexadecimal ? 2 : 1)
        let numberString = self[numberStartIndex ..< endIndex]

        guard let codePoint = UInt32(numberString, radix: radix),
              let scalar = UnicodeScalar(codePoint) else {
            return nil
        }

        return String(scalar)
    }
}
