#!/usr/bin/swift

import Foundation

//MARK: Helpers

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

// MARK: Load

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

// MARK: Types

// Whether the string needs multiple representations based on a numeric parameter
enum Plurality {
    case Single
    case Multi
}

func == (left : Key, right : Key) -> Bool {
    return left.path == right.path && left.name == right.name
}

struct Key : Hashable, Equatable {
    let path : [String]
    let name : String
    let original : String
    
    var hashValue : Int {
        return name.hashValue ^ path.reduce(0) {$0 ^ $1.hashValue}
    }
}

class Group {
    let name : String
    var children : [String:Group] = [:]
    var items : [Item] = []
    
    init(name : String) {
        self.name = name
    }
}

// A localization item
class Item {
    let key : Key
    var values : [String]
    let arguments : [String]
    let plurality : Plurality
    
    init(key : Key, values: [String], arguments: [String], plurality: Plurality) {
        self.key = key
        self.values = values
        self.arguments = arguments
        self.plurality = plurality
    }
}

enum ArgumentError : ErrorType {
    case Unterminated
}

// MARK: Formatting

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

extension Item {
    
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
                return "static func \(variableName(key.name))(\(args)) -> String { return OEXLocalizedString(\"\(key.name)\", nil).oex_formatWithParameters([\(formatParams)]) }"
            case .Multi:
                if arguments.count == 1 {
                    let arg = arguments[0]
                    let name = variableName(arg)
                    return "static func \(variableName(key.name))(\(name) \(name) : Float) -> String { return OEXLocalizedStringPlural(\"\(key.name)\", \(name), nil).oex_formatWithParameters([\"\(arg)\": \(name)]) }"
                }
                else {
                    return "static func \(variableName(key.name))(pluralizingCount : Float)(\(args)) -> String { return OEXLocalizedStringPlural(\"\(key.name)\", pluralizingCount, nil).oex_formatWithParameters([\(formatParams)]) }"
                }
            }
        }
        else {
            switch plurality {
            case .Single:
                return "static var \(variableName(key.name)) = OEXLocalizedString(\"\(key.name)\", nil)"
            case .Multi:
                return "static func \(variableName(key.name))(count : Float) -> String { return OEXLocalizedStringPlural(\"\(key.name)\", count, nil) } "
            }
        }
    }
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


/// Takes a string key of the form A.B.C##count and returns a parsed Key and the plurality
/// For example, FOO.BAR.BAZ##other would return (Key(path:[FOO, BAR], name:BAZ), .Multi)
func parseKey(key : String) -> (Key, Plurality) {
    let components = key.componentsSeparatedByString(".")
    let path = Array(components[0 ..< components.count - 1])

    guard let base = components.last else {
        print("error: Invalid Key \(key)", toStream:&errorStream)
        exit(1)
    }
    let parts = base.componentsSeparatedByString("##")
    if parts.count > 1 {
        return (Key(path: path, name: parts[0], original:key), .Multi)
    }
    else {
        return (Key(path:path, name: base, original:key), .Single)
    }
}

//MARK: Process Items

// Check that all items have a comment
func verifyItems(items : [Item]) {
    var foundError = false
    guard let content = NSString(contentsOfFile: source) else {
        print("error: Could not open file \(source).", toStream: &errorStream)
        exit(1)
    }
    for item in items {
        let key = "\"\(item.key.original)\""
        let range = content.rangeOfString(key)
        guard range.location != NSNotFound else {
            print("error: Couldn't find key: \(key)", toStream:&errorStream)
            continue
        }
        // This is super hacky. Just look for the original key and make sure there's a comment close marker a little bit before it.
        let commentClose = content.rangeOfString("*/", options:NSStringCompareOptions(), range:NSRange(location: max(range.location, 20) - 20, length:20))
        if commentClose.location == NSNotFound {
            print("error: Missing comment for string \(item.key.original). This information is needed by translators.")
            foundError = true
        }
    }
    if foundError {
        exit(1)
    }
}

// First pass get the items and verify they're okay
var items : [Key : Item] = [:]
for pair in pairs {
    let stringKey = pair.key as! String
    let value = pair.value as! String
    
    let (key, plurality) = parseKey(stringKey)
    
    do {
        let arguments = try getArguments(value)
        if let existing = items[key] {
            if Set(existing.arguments) != Set(arguments) {
                print("error: Plural cases have different arguments. Key: \(key.name). Arguments: \(existing.arguments) & \(arguments)", toStream: &errorStream)
                exit(1)
            }
            existing.values.append(value)
        }
        else {
            let item = Item(key: key, values: [value], arguments: arguments, plurality: plurality)
            items[key] = item
        }
    }
    catch {
        print("error: Invalid string \(value)", toStream: &errorStream)
        exit(1)
    }
}

verifyItems(Array(items.values))

// Second pass. Group them by path so we get nested structures
var topLevel = Group(name:"Strings")
for item in items.values {
    var currentGroup = topLevel
    for segment in item.key.path {
        if let child = currentGroup.children[segment] {
            currentGroup = child
        }
        else {
            let child = Group(name:segment)
            currentGroup.children[segment] = child
            currentGroup = child
        }
    }
    currentGroup.items.append(item)
}

//MARK: Output

func tabs(number : UInt) -> String {
    var result : String = ""
    for _ in 0..<number {
        result += "\t"
    }
    return result
}

guard var output = FileOutputStream(path:dest) else {
    print("error: Couldn't open file \(dest) for writing", toStream: &errorStream)
    exit(1)
}

func printGroup(group : Group, depth : UInt = 0) {
    let indent = tabs(depth)
    print("\(indent)struct \(variableName(group.name).capitalizedString) {", toStream: &output)
    if group.children.count > 0 {
        print("", toStream: &output)
        for name in group.children.keys.sort() {
            let child = group.children[name]!
            printGroup(child, depth: depth + 1)
        }
        print("", toStream: &output)
    }
    
    if group.items.count > 0 {
        let childIndent = tabs(depth + 1)
        print("", toStream: &output)
        for item in (group.items.sort {$0.key.name < $1.key.name}) {
            print("\(childIndent)\(item.code)", toStream: &output)
        }
        print("", toStream: &output)
    }
    print("\(indent)}", toStream: &output)
}

print("// This file is autogenerated. Do not modify.", toStream: &output)
print("\n", toStream: &output)

printGroup(topLevel)

print("", toStream: &output)
