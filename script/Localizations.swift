#!/usr/bin/xcrun -sdk macosx swift

import Foundation

//MARK: Helpers

// Stream that writes to stderr.
class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
    
}

var errorStream = StandardErrorOutputStream()

// This makes it easy to ``print`` to a file
class FileOutputStream : TextOutputStream {
    let handle : FileHandle
    init?(path : String) {
        if !FileManager.default.createFile(atPath: path, contents:nil, attributes:nil) {
            self.handle = FileHandle.nullDevice
            return nil
        }
        if let handle = FileHandle(forWritingAtPath:path) {
            self.handle = handle
        }
        else {
            self.handle = FileHandle.nullDevice
            return nil
        }
    }
    
    func write(_ string: String) {
        handle.write(string.data(using: String.Encoding.utf8)!)
    }
    
    deinit {
        handle.closeFile()
    }
}

// MARK: Load

let arguments = CommandLine.arguments
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
    print("error: Unable to load strings file: \(source)", to: &errorStream)
    exit(1)
}

// MARK: Types

// Whether the string needs multiple representations based on a numeric parameter
enum Plurality {
    case single
    case multi
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
    
    var arrayItem: Bool { return Int(key.name) != nil }
}

enum ArgumentError : Error {
    case unterminated
}

// MARK: Formatting

func symbolName(_ string : String, leadingCapital: Bool) -> String {
    let parts = string.components(separatedBy: "_")
    var formattedParts : [String] = []
    var first = true
    for part in parts {
        if first && !leadingCapital {
            formattedParts.append(part.lowercased())
        }
        else {
            formattedParts.append(part.capitalized)
        }
        first = false
    }
    return formattedParts.joined(separator: "")
}

func variableName(_ string : String) -> String {
    return symbolName(string, leadingCapital: false)
}

func className(_ string : String) -> String {
    return symbolName(string, leadingCapital: true)
}

extension Item {
    
    var code : String {
        if arguments.count > 0 {
            let args = arguments.map {
                return "\(variableName($0)) : String"
                }.joined(separator: ", ")
            let formatParams = arguments.map {
                return "\"\($0)\" : \(variableName($0))"
                }.joined(separator: ", ")
            
            switch plurality {
            case .single:
                return "static func \(variableName(key.name))(\(args)) -> String { return OEXLocalizedString(\"\(key.original)\", nil).oex_format(withParameters: [\(formatParams)]) }"
            case .multi:
                if arguments.count == 1 {
                    let arg = arguments[0]
                    let name = variableName(arg)
                    return "static func \(variableName(key.name))(\(name) : Int, formatted : String? = nil) -> String { return OEXLocalizedStringPlural(\"\(key.name)\", \(name), nil).oex_format(withParameters: [\"\(arg)\": formatted ?? \(name).description]) }"
                    
                }
                else {
                    return "static func \(variableName(key.name))(\(args)) -> ((Int) -> String) { return {pluralizingCount in OEXLocalizedStringPlural(\"\(key.name)\", pluralizingCount, nil).oex_format(withParameters: [\(formatParams)]) }}"
                }
            }
        }
        else {
            switch plurality {
            case .single:
                return "static var \(variableName(key.name)) = OEXLocalizedString(\"\(key.original)\", nil)"
            case .multi:
                return "static func \(variableName(key.name))(count : Int) -> String { return OEXLocalizedStringPlural(\"\(key.name)\", count, nil) } "
            }
        }
    }
}

func getArguments(_ string : String) throws -> [String] {
    var arguments : [String] = []
    var current = string.startIndex
    
    while current < string.endIndex {
        if let start = string.range(of: "{", options:NSString.CompareOptions(), range:current ..< string.endIndex) {
            if let end = string.range(of: "}", options:NSString.CompareOptions(), range:start.lowerBound ..< string.endIndex) {
                
                let argument = string[string.index(after: start.lowerBound)..<string.index(before: end.upperBound)]
                
                arguments.append(String(argument))
                current = end.upperBound
            }
            else {
                throw ArgumentError.unterminated
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
func parseKey(_ key : String) -> (Key, Plurality) {
    let components = key.components(separatedBy: ".")
    let path = Array(components[0 ..< components.count - 1])
    
    guard let base = components.last else {
        print("error: Invalid Key \(key)", to:&errorStream)
        exit(1)
    }
    let parts = base.components(separatedBy: "##")
    if parts.count > 1 {
        return (Key(path: path, name: parts[0], original:key), .multi)
    }
    else {
        return (Key(path:path, name: base, original:key), .single)
    }
}

//MARK: Process Items

// Check that all items have a comment
func verifyItems(_ items : [Item]) {
    var foundError = false
    guard let content = try? NSString(contentsOfFile: source, encoding: String.Encoding.utf8.rawValue) else {
        print("error: Could not open file \(source).", to: &errorStream)
        exit(1)
    }
    for item in items {
        let key = "\"\(item.key.original)\""
        let range = content.range(of: key)
        guard range.location != NSNotFound else {
            print("error: Couldn't find key: \(key)", to:&errorStream)
            continue
        }
        // This is super hacky. Just look for the original key and make sure there's a comment close marker a little bit before it.
        let commentClose = content.range(of: "*/", options:NSString.CompareOptions(), range:NSRange(location: max(range.location, 20) - 20, length:20))
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
                print("error: Plural cases have different arguments. Key: \(key.name). Arguments: \(existing.arguments) & \(arguments)", to: &errorStream)
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
        print("error: Invalid string \(value)", to: &errorStream)
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

func tabs(_ number : UInt) -> String {
    var result : String = ""
    for _ in 0..<number {
        result += "\t"
    }
    return result
}

guard var output = FileOutputStream(path:dest) else {
    print("error: Couldn't open file \(dest) for writing", to: &errorStream)
    exit(1)
}

func printArray(_ group : Group, indent: String) {
    var values = [String]()
    let sortedItems = group.items.sorted { return $0.key.name.compare($1.key.name) == .orderedAscending }
    for item in sortedItems {
        values.append("OEXLocalizedString(\"\(item.key.original)\", nil)")
    }
    print("\(indent)static var \(variableName(group.name)) = [\(values.joined(separator: ", "))]", to: &output)
}

func printGroup(_ group : Group, depth : UInt = 0) {
    let indent = tabs(depth)
    guard !(group.items.first?.arrayItem ?? false) else {
        printArray(group, indent: indent)
        return
    }
    
    print("\(indent)@objc class \(className(group.name)) : NSObject {", to: &output)
    if group.children.count > 0 {
        print("", to: &output)
        for name in group.children.keys.sorted() {
            let child = group.children[name]!
            printGroup(child, depth: depth + 1)
        }
        print("", to: &output)
    }
    
    if group.items.count > 0 {
        let childIndent = tabs(depth + 1)
        print("", to: &output)
        for item in (group.items.sorted {$0.key.name < $1.key.name}) {
            print("\(childIndent)\(item.code)", to: &output)
        }
        print("", to: &output)
    }
    print("\(indent)}", to: &output)
}

print("// This file is autogenerated. Do not modify.", to: &output)
print("\n", to: &output)

printGroup(topLevel)

print("", to: &output)
