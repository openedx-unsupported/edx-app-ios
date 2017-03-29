//
//  NSUUID+Username.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension UUID {

    // We want to generate random usernames for tests, so ideally we would just generate a UUID.
    // But regular UUIDs are too long to be an edX username.
    // UUIDs are ascii-encoded hex. That is 4 bits (one hex digit) per character.
    // As such we convert the string to base64 which is a denser encoding (6 bits per character).
    // This is kind of hacky, but it does the job and seems pretty safe
    var asUsername: String {

        /// Converts an ascii hex digit to its numerical representation.
        /// For example, hexValue("F") = 15, hexValue("7") = 7.
        /// *Crashes* if given a character outside [0-9A-F].
        /// As such, it should be used carefully and is not suitable for use outside of test code.
        func hexValue(_ scalar : UnicodeScalar) -> UInt32 {
            enum Sentinal : String {
                case A = "A"
                case F = "F"
                case Zero = "0"
                case Nine = "9"

                var value : UInt32 {
                    return self.rawValue.unicodeScalars.first!.value
                }
            }

            let v = scalar.value
            switch v {
            case Sentinal.Zero.value ... Sentinal.Nine.value:
                return v - Sentinal.Zero.value
            case Sentinal.A.value ... Sentinal.F.value:
                return v - Sentinal.A.value + 10
            default:
                preconditionFailure("Unexpected ascii char with value:\(v)")
            }
        }

        let hex = self.uuidString.components(separatedBy: "-").joined(separator: "")
        var accumulator : [UInt32] = []

        // Create a buffer that will be our UUID hex string as actual hex bytes
        // For example, if our UUID starts "AF" then the first byte of data
        // will be 0xAF.
        let data = NSMutableData(capacity: 0)!

        // Add the digits to our buffer in two character (one byte) chunks
        for character in hex.unicodeScalars {
            accumulator.append(hexValue(character))
            if(accumulator.count == 2) {
                var value = accumulator[0] + (accumulator[1] << 4)
                data.append(&value, length: 1)
                accumulator.removeAll()
            }
        }

        var result = data.base64EncodedString(options: .lineLength64Characters)
        for remaining in accumulator {
            result.append(String(describing: UnicodeScalar(remaining)))
        }
        // Replace characters not allowed in usernames and remove the unnecessary tail of "=" from base64.
        // It doesn't matter how we do this exactly, since we never decode this out of base64.
        // Our goal is just to get a unique token that only users username safe characters
        return result
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "+", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
