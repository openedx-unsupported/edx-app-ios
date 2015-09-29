#!/usr/bin/swift

import Foundation

// Stream that writes to stderr.
class StandardErrorOutputStream: OutputStreamType {
    func write(string: String) {
        fputs(string, stderr)
    }
}

var errorStream = StandardErrorOutputStream()

// This makes it easy to ``print`` to a file
class FileOutputStream : OutputStreamType {
    let handle : NSFileHandle
    init?(path : String) {
        if !NSFileManager.defaultManager().createFileAtPath(path, contents:nil, attributes:nil) {
            self.handle = NSFileHandle.fileHandleWithNullDevice()
            return nil
        }
        if let handle = NSFileHandle(forWritingAtPath:path) {
            self.handle = handle
        }
        else {
            self.handle = NSFileHandle.fileHandleWithNullDevice()
            return nil
        }
    }
    
    func write(string: String) {
        handle.writeData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    deinit {
        handle.closeFile()
    }
}


let arguments = Process.arguments
guard arguments.count > 2 else {
    print("error: Not enough arguments. Aborting")
    print("Usage: ")
    print("Localizations.swift <source_file> <dest_file>")
    exit(1)
}

let source = arguments[1]
let dest = arguments[2]
print("Loading \(source) into \(dest)")

guard let pairs = NSDictionary(contentsOfFile: source) else {
    print("error: Unable to load strings file: \(source)", toStream: &errorStream)
    exit(1)
}

// Whether the string needs multiple representations based on a numeric parameter
enum Plurality {
    case Single
    case Multi
}

// A localization item
class Item {
    let key : String
    var values : [String]
    let arguments : [String]
    let plurality : Plurality
    
    init(key : String, values: [String], arguments: [String], plurality: Plurality) {
        self.key = key
        self.values = values
        self.arguments = arguments
        self.plurality = plurality
    }
    
    func variableName(string : String) -> String {
        let parts = string.componentsSeparatedByString("_")
        var formattedParts : [String] = []
        var first = true
        for part in parts {
            if first {
               formattedParts.append(part.lowercaseString)
            }
            else {
                formattedParts.append(part.capitalizedString)
            }
            first = false
        }
        return formattedParts.joinWithSeparator("")
    }
    
    var code : String {
        if arguments.count > 0 {
            let args = arguments.map {
                return "\(variableName($0)) : String"
                }.joinWithSeparator(", ")
            let formatParams = arguments.map {
                return "\"\($0)\" : \(variableName($0))"
                }.joinWithSeparator(", ")
            
            switch plurality {
            case .Single:
                return "\tstatic func \(variableName(key))(\(args)) -> String { return OEXLocalizedString(\"\(key)\", nil).oex_formatWithParameters([\(formatParams)]) }"
            case .Multi:
                if arguments.count == 1 {
                    let arg = arguments[0]
                    let name = variableName(arg)
                    return "\t static func \(variableName(key))(\(name) \(name) : Float) -> String { return OEXLocalizedStringPlural(\"\(key)\", \(name), nil).oex_formatWithParameters([\"\(arg)\": \(name)]) }"
                }
                else {
                    return "\tstatic func \(variableName(key))(pluralizingCount : Float)(\(args)) -> String { return OEXLocalizedStringPlural(\"\(key)\", pluralizingCount, nil).oex_formatWithParameters([\(formatParams)]) }"
                }
            }
        }
        else {
            switch plurality {
            case .Single:
                return "\tstatic var \(variableName(key)) = OEXLocalizedString(\"\(key)\", nil)"
            case .Multi:
                return "\tstatic func \(variableName(key))(count : Float) -> String { return OEXLocalizedStringPlural(\"\(key)\", count, nil) } "
            }
        }
    }
}

enum ArgumentError : ErrorType {
    case Unterminated
}


func getArguments(string : String) throws -> [String] {
    var arguments : [String] = []
    var current = string.startIndex

    while current < string.endIndex {
        if let start = string.rangeOfString("{", options:NSStringCompareOptions(), range:Range(start:current, end:string.endIndex)) {
            if let end = string.rangeOfString("}", options:NSStringCompareOptions(), range:Range(start:start.startIndex, end:string.endIndex)) {
                let argument = string[start.startIndex.successor()..<end.endIndex.predecessor()]
                arguments.append(argument)
                current = end.endIndex
            }
            else {
                throw ArgumentError.Unterminated
            }
        }
        else {
            break
        }
    }
    return arguments
}

func parseKey(key : String) -> (String, Plurality) {
    let parts = key.componentsSeparatedByString("##")
    if parts.count > 1 {
        return (parts[0], .Multi)
    }
    else {
        return (key, .Single)
    }
}

var items : [String:Item] = [:]
for pair in pairs {
    let key = pair.key as! String
    let value = pair.value as! String
    
    let (base, plurality) = parseKey(key)
    
    do {
        let arguments = try getArguments(value)
        if let existing = items[base] {
            if Set(existing.arguments) != Set(arguments) {
                print("error: Plural cases have different arguments. Key: \(base). Arguments: \(existing.arguments) & \(arguments)", toStream: &errorStream)
                exit(1)
            }
            existing.values.append(value)
        }
        else {
            let item = Item(key: base, values: [value], arguments: arguments, plurality: plurality)
            items[base] = item
        }
    }
    catch {
        print("error: Invalid string \(value)", toStream: &errorStream)
        exit(1)
    }
}

guard var output = FileOutputStream(path:dest) else {
    print("error: Couldn't open file \(dest) for writing", toStream: &errorStream)
    exit(1)
}

print("// This file is autogenerated. Do not modify.", toStream: &output)
print("\n", toStream: &output)
print("struct Strings {", toStream: &output)
print("", toStream: &output)

for key in items.keys.sort() {
    if let item = items[key] {
        print("\(item.code)", toStream: &output)
    }
}

print("", toStream: &output)
print("}", toStream: &output)

print("", toStream: &output)
