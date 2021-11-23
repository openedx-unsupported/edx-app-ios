#!/usr/bin/xcrun -sdk macosx swift
import Foundation

var topLevel = Group(name:"Strings")
var topLevelItems: [Key : Item] = [:]

// Stream that writes to stderr.
class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

var errorStream = StandardErrorOutputStream()

// Whether the string needs multiple representations based on a numeric parameter
enum Plurality {
    case single
    case multi
}

func == (left: Key, right: Key) -> Bool {
    return left.path == right.path && left.name == right.name
}

struct Key: Hashable {
    let path: [String]
    let name: String
    let original: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(path.reduce(0) {$0 ^ $1.hashValue})
    }
}

class Group {
    let name: String
    var children: [String:Group] = [:]
    var items: [Item] = []
    
    init(name: String) {
        self.name = name
    }
}

// A localization item
class Item {
    let key: Key
    var values: [String]
    let arguments: [String]
    let plurality: Plurality
    let file: String
    
    init(key: Key, values: [String], arguments: [String], plurality: Plurality, file: String) {
        self.key = key
        self.values = values
        self.arguments = arguments
        self.plurality = plurality
        self.file = file
    }
    
    var arrayItem: Bool { return Int(key.name) != nil }
    
    var code: String {
        let table = URL(string: file)?.deletingPathExtension().lastPathComponent ?? ""
        
        if arguments.count > 0 {
            let args = arguments.map {
                return "\(variableName($0)): String"
            }.joined(separator: ", ")
            let formatParams = arguments.map {
                return "\"\($0)\": \(variableName($0))"
            }.joined(separator: ", ")
            
            switch plurality {
            case .single:
                return "@objc static func \(variableName(key.name))(\(args)) -> String { return OEXLocalizedStringFromTable(\"\(key.original)\", \"\(table)\", nil).oex_format(withParameters: [\(formatParams)]) }"
            case .multi:
                if arguments.count == 1 {
                    let arg = arguments[0]
                    let name = variableName(arg)
                    return "@objc static func \(variableName(key.name))(\(name): Int, formatted: String? = nil) -> String { return OEXLocalizedStringPluralFromTable(\"\(key.name)\", \"\(table)\", \(name), nil).oex_format(withParameters: [\"\(arg)\": formatted ?? \(name).description]) }"
                } else {
                    return "@objc static func \(variableName(key.name))(\(args)) -> ((Int) -> String) { return { pluralizingCount in OEXLocalizedStringPluralFromTable(\"\(key.name)\", \"\(table)\", pluralizingCount, nil).oex_format(withParameters: [\(formatParams)]) }}"
                }
            }
        } else {
            switch plurality {
            case .single:
                return "@objc static var \(variableName(key.name)) = OEXLocalizedStringFromTable(\"\(key.original)\", \"\(table)\", nil)"
            case .multi:
                return "@objc static func \(variableName(key.name))(count: Int) -> String { return OEXLocalizedStringPluralFromTable(\"\(key.name)\",  \"\(table)\", count, nil) }"
            }
        }
    }
}

enum ArgumentError: Error {
    case unterminated
}

func symbolName(_ string: String, leadingCapital: Bool) -> String {
    let parts = string.components(separatedBy: "_")
    var formattedParts: [String] = []
    var first = true
    for part in parts {
        if first && !leadingCapital {
            formattedParts.append(part.lowercased())
        } else {
            formattedParts.append(part.capitalized)
        }
        first = false
    }
    return formattedParts.joined(separator: "")
}

func variableName(_ string: String) -> String {
    return symbolName(string, leadingCapital: false)
}

func className(_ string: String) -> String {
    return symbolName(string, leadingCapital: true)
}

func getArguments(_ string: String) throws -> [String] {
    var arguments: [String] = []
    var current = string.startIndex
    
    while current < string.endIndex {
        if let start = string.range(of: "{", options:NSString.CompareOptions(), range:current ..< string.endIndex) {
            if let end = string.range(of: "}", options:NSString.CompareOptions(), range:start.lowerBound ..< string.endIndex) {
                let argument = string[string.index(after: start.lowerBound)..<string.index(before: end.upperBound)]
                arguments.append(String(argument))
                current = end.upperBound
            } else {
                throw ArgumentError.unterminated
            }
        } else {
            break
        }
    }
    return arguments
}


/// Takes a string key of the form A.B.C##count and returns a parsed Key and the plurality
/// For example, FOO.BAR.BAZ##other would return (Key(path:[FOO, BAR], name:BAZ), .Multi)
func parseKey(_ key: String) -> (Key, Plurality) {
    let components = key.components(separatedBy: ".")
    let path = Array(components[0 ..< components.count - 1])
    
    guard let base = components.last else {
        print("error: Invalid Key \(key)", to: &errorStream)
        exit(1)
    }
    let parts = base.components(separatedBy: "##")
    if parts.count > 1 {
        return (Key(path: path, name: parts[0], original: key), .multi)
    } else {
        return (Key(path:path, name: base, original: key), .single)
    }
}

let arguments = CommandLine.arguments
guard arguments.count > 2 else {
    print("error: Not enough arguments. Aborting")
    print("Usage: ")
    print("Localizations.swift <source_directory> <destination_file>")
    exit(1)
}
let source = arguments[1]
let destination = arguments[2]

let url = URL(fileURLWithPath: destination)
try? "".write(to: url, atomically: false, encoding: .utf8)

let fileUpdater = try? FileHandle(forUpdating: url)

func writeToFile(_ text: String) {
    let formattedText = text + "\n"
    // Function which when called will cause all updates to start from end of the file
    fileUpdater?.seekToEndOfFile()
    // Which lets the caller move editing to any position within the file by supplying an offset
    fileUpdater?.write(formattedText.data(using: .utf8)!)
    // Once we convert our new content to data and write it, we close the file and that’s it!
}

func readFileContentsAndVerify(_ path: String) -> NSDictionary {
    guard let pairs = NSDictionary(contentsOfFile: source) else {
        print("error: Could not read file \(path)", to:&errorStream)
        exit(1)
    }
    return pairs
}

// Check that all items have a comment
func verifyItems(_ items: [Item], _ file: String) -> Bool {
    var foundError = false
    guard let content = try? NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue) else {
        print("error: Could not open file \(file)", to: &errorStream)
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
        print("error: Some error occured while parsing file: \(file)", to: &errorStream)
        exit(1)
    } else {
        return true
    }
}

func verifyPairs(_ pairs: NSDictionary, _ file: String) {
    var items: [Key : Item] = [:]
    
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
            } else {
                let item = Item(key: key, values: [value], arguments: arguments, plurality: plurality, file: file)
                items[key] = item
            }
        } catch {
            print("error: Invalid string \(value)", to: &errorStream)
            exit(1)
        }
    }
    
    if verifyItems(Array(items.values), file) {
        for item in items.values {
            var currentGroup = topLevel
            for segment in item.key.path {
                if let child = currentGroup.children[segment] {
                    currentGroup = child
                } else {
                    let child = Group(name:segment)
                    currentGroup.children[segment] = child
                    currentGroup = child
                }
            }
            currentGroup.items.append(item)
        }
    } else {
        print("error: Unable to verify Items", to: &errorStream)
        exit(1)
    }
}

func readDictionary(_ file: String) {
    guard let pairs = NSDictionary(contentsOfFile: file) else {
        print("error: Could not read file \(file)", to: &errorStream)
        exit(1)
    }
    
    verifyPairs(pairs, file)
}

func tabs(_ number: UInt) -> String {
    var result: String = ""
    for _ in 0..<number {
        result += "\t"
    }
    return result
}

func printArray(_ group: Group, indent: String) {
    var values = [String]()
    let sortedItems = group.items.sorted { return $0.key.name.compare($1.key.name) == .orderedAscending }
    for item in sortedItems {
        let table = URL(string: source)?.deletingPathExtension().lastPathComponent ?? ""
        values.append("OEXLocalizedStringFromTable(\"\(item.key.original)\", \"\(table)\", nil)")
        writeToFile("")
    }
    writeToFile("\(indent)static var \(variableName(group.name)) = [\(values.joined(separator: ", "))]")
    writeToFile("")
}

func printGroup(_ group: Group, depth: UInt = 0) {
    let indent = tabs(depth)
    guard !(group.items.first?.arrayItem ?? false) else {
        printArray(group, indent: indent)
        return
    }
    
    writeToFile("\(indent)@objc class \(className(group.name)): NSObject {")
    writeToFile("")
    if group.children.count > 0 {
        for name in group.children.keys.sorted() {
            let child = group.children[name]!
            printGroup(child, depth: depth + 1)
        }
    }
    
    if group.items.count > 0 {
        let childIndent = tabs(depth + 1)
        for item in (group.items.sorted {$0.key.name < $1.key.name}) {
            writeToFile("\(childIndent)\(item.code)")
        }
    }
    writeToFile("\(indent)}")
    writeToFile("")
}

// list all files in directory
func prepareItemsFromFiles(_ path: String)  {
    var results = [String]()
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: path) else {
        print("error: unable to enumerate file at: \(path)", to: &errorStream)
        exit(1)
    }
    for file in enumerator.allObjects as! [String] {
        if !file.hasPrefix("InfoPlist") && file.hasSuffix(".strings") {
            results.append(file)
        }
    }
    
    for result in results {
        let file = "\(path)/\(result)"
        readDictionary(file)
    }
}

prepareItemsFromFiles(source)
writeToFile("// This file is autogenerated. Do not modify. \n")
printGroup(topLevel)

fileUpdater?.closeFile()
