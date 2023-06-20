//
//  run-symbol-tool.swift
//  2022 New Relic
//
// Swift script used to upload a builds symbols to New Relic.
// Intended to be run from a Xcode build phase.
//
// 1. In Xcode, select your project in the navigator, then click on the application target.
// 2. Select the Build Phases tab in the settings editor.
// 3. Click the + icon above Target Dependencies and choose New Run Script Build Phase.
// 4. Add the following line of code to the new phase, pasting in the
//     application token from your New Relic dashboard for the app in question.
// 
//  "${BUILD_DIR%/Build/*}/SourcePackages/artifacts/newrelic-ios-agent-spm/NewRelic.xcframework/Resources/run-symbol-tool" "APP_TOKEN"
// 
// Optional:
// DSYM_UPLOAD_URL - define this environment variable above run script to override the New Relic server hostname
//
// - Due to limitations with Swift scripting run-symbol-tool.swift is one file.
//   Main script contents are in start() func. Helper functions are categorized at the end.
// - Script will first attempt to convert each dSYM into NR map files, 
//   then it will combine map files into zip file and upload to New Relic.
//   If conversion isn't possible or zipped map files upload fails the dSYMs are uploaded to New Relic.
// ============================================================================
// START of Script run-symbol-tool.swift
import Foundation

let defaultURL = "https://mobile-symbol-upload.newrelic.com"
let fileManager = FileManager.default
let environment = ProcessInfo.processInfo.environment
// Set to true for additional debug info in the upload_dsym_results.log file.
var debug = false
// Set to true for dSYM upload feature. (dSYM files are normally only uploaded if map file conversion fails.)
let uploadDsymsOnly = false

enum SymbolToolError: Error {
    case failedToConvert
    case failedToUpload
}

start()

func start() {
    print("New Relic: Starting dSYM upload script...")

    let isBitcodeEnabled = environment["ENABLE_BITCODE"] == "YES"
    guard !isBitcodeEnabled else {
        print("New Relic: Build is Bitcode enabled. No dSYM has been uploaded. Bitcode enabled apps require dSYM files to be downloaded from App Store Connect. For more information please review https://docs.newrelic.com/docs/mobile-monitoring/new-relic-mobile-ios/install-configure/retrieve-upload-dsyms  Exiting without failure.")
        exit(0)
    }

    let directory = environment["DWARF_DSYM_FOLDER_PATH"]
    let platformName = environment["EFFECTIVE_PLATFORM_NAME"]

    if platformName == "-iphonesimulator" {
        print("New Relic: Skipping automatic upload of simulator build symbols")
        exit(0)
    }

    guard CommandLine.arguments.count > 1 else {
        // Must contain at least one argument: $APP_TOKEN. (--debug is optional)
        print("Invalid Usage: Ex: Swift: run-symbol-tool.swift $APP_TOKEN [--debug]")
        exit(1)
    }
    let apiKey = CommandLine.arguments[1]
    
    if CommandLine.arguments.count == 3 {
        let debugFlag = CommandLine.arguments[2]
        if debugFlag == "--debug" {
            debug = true
        }
    }

    // Grab URL from set Env Var "$DSYM_UPLOAD_URL" or use default URL.
    var url = environment["DSYM_UPLOAD_URL"] ?? defaultURL

    if let regionAwareURL = parseRegionFromApiKey(apiKey) {
        url = regionAwareURL
        print("**** Using Region Aware URL: \(url)")
    }

    if debug {
        print("========== dSYM directory = \(directory ?? "NOT FOUND")")
        print("========== Platform = \(platformName ?? "NOT FOUND")")
        print("========== URL = \(url)")
        print("========== apiKey = \(apiKey)")
    }

    guard let directory = directory else { 
        print("No directory to work on. ($DWARF_DSYM_FOLDER_PATH) Exiting.")
        exit(1)
    }

    var dSYMPaths = [String]()
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: directory)
        for content in contents where content.hasSuffix(".dSYM") {
            dSYMPaths.append("\(directory)/\(content)")
        }
    } catch {
        print(error)
        print("Error: We've encountered an error opening the dSYM directory. Exiting.")
        exit(1)
    }
    
    if debug { print("dSYMs located at: \(dSYMPaths)") }
    guard !dSYMPaths.isEmpty else {
        print("Error: No dSYMs found to process. Make sure your Xcode project target build setting 'Debug Information Format' is set to 'DWARF with dSYM File'.  Exiting.")
        exit(1)
    }
    // Attempt to convert each dSYM to a New Relic map file. If an error is encountered during conversion or map upload the dSYMs will be uploaded.
    for debugSymbolPath in dSYMPaths {
        func fallback() {
            print("Falling back to upload zipped dSYM...")
            do {
                try zipAndUploadDsym(debugSymbolPath, apiKey, url)
            } catch {
                print(error)
            }
        }

        if uploadDsymsOnly {
            print("*** uploadDsymsOnly is set to true. Performing dSYM upload...")
            fallback()
            continue
        }

        // If dSYM fails to be converted to map file we skip to upload the dSYM.
        do {
            try processDsym(debugSymbolPath, apiKey, url)
        } catch {
            print("Error in conversion: \(error) encountered processing dSYM at path: \(debugSymbolPath)")
            // Fallback to upload the dSYM due to error encountered processing dSYM->Map or uploading map.
            fallback()
        }
    }
}
// END of Script run-symbol-tools.swift
// ============================================================================

func zipAndUploadDsym(_ dsymPath: String, _ apiKey: String, _ url: String) throws {
    guard let tempDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        throw SymbolToolError.failedToConvert
    }
    
    let tempDirURL = tempDir.appendingPathComponent("\(UUID())")    
    try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    let dsymUrl = URL(fileURLWithPath: dsymPath)
    let newURL = tempDirURL.appendingPathComponent(dsymUrl.lastPathComponent)
    try fileManager.copyItem(at: dsymUrl, to: newURL)
        
    // Now that the dSYM file is in tempDirURL dir lets zip it up.
    let coordinator = NSFileCoordinator()
    var zipError: NSError?
    var archiveUrl: URL?

    coordinator.coordinate(readingItemAt: tempDirURL, options: .forUploading, error: &zipError) { zipURL in
        do {
            let temporaryURL =  tempDirURL.appendingPathComponent("dsymArchive.zip")
            try fileManager.copyItem(at: zipURL, to: temporaryURL)
            archiveUrl = temporaryURL

            if let archiveUrl = archiveUrl {

                print("successfully zipped dSYM to \(archiveUrl)")

                // Now that we have archiveUrl with the dSYM file zipped up, upload the zip file.
                let dsymUploadResult = try uploadFile(archiveUrl.path, apiKey, url, true)
                if dsymUploadResult == "201" {
                    print("Successfully uploaded dSYM: \(archiveUrl.path)")
                }
                else {
                    print("*** Failed w/ error: \(dsymUploadResult ?? "NO ERROR") when upload dSYM: \(archiveUrl.path)")
                }
                // Remove copied dSYM and zipped dSYM and temporary folder.
                try fileManager.removeItem(at: tempDirURL)
            }
        }
        catch {
            print(error)
        }
    }
}

// Helper Functions
func processDsym(_ path: String, _ apiKey: String, _ url: String) throws {
    var resultFromSymbolsUUID: String? = nil
    do {
        if debug { print("Executing $ symbols -uuid '\(path)'") }
        resultFromSymbolsUUID = try shell("symbols -uuid '\(path)'")
    } catch {
        print("\(error) running symbols --uuid. Exiting.")
        throw SymbolToolError.failedToConvert
    }
    guard let resultFromSymbolsUUID = resultFromSymbolsUUID else {
        print("`symbols -uuid` Result is nil. Exiting.")
        throw SymbolToolError.failedToConvert
    }

    if debug { print("result from symbols --uuid: \(resultFromSymbolsUUID)") }
    var uuidDict = [String: String]()
    let lines = resultFromSymbolsUUID.split(whereSeparator: \.isNewline)
    for line in lines where !line.isEmpty {
        let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        if parts.count > 1  {
            let uuid = parts[0].lowercased().replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
            let arch = parts[1].trimmingCharacters(in: .whitespaces)
            uuidDict[uuid] = arch
        }
        else {
            print("failed to parse parts of \(line)")
            throw SymbolToolError.failedToConvert
        }
    }
    if debug { print("Parsed uuids: \(uuidDict)") }

    var mapURLs = [URL]()
    for (key, value) in uuidDict {
        var resultFromSymbolsArch: String? = nil
        do {
            if debug { print("Executing $ symbols -arch \(value) '\(path)'") }
            resultFromSymbolsArch = try shell("symbols -arch \(value) '\(path)'")
        } catch {
            print("\(error). Exiting dSYM conversion process.")
            throw SymbolToolError.failedToConvert
        }
        guard let resultFromSymbolsArch = resultFromSymbolsArch else {
            print("symbols -arch` Result is nil. Exiting dSYM conversion process.")
            throw SymbolToolError.failedToConvert
        }
        
        do {
            let url = try processSymbolsOutput(resultFromSymbolsArch, key, value)
            mapURLs.append(url)
        } catch {
            print("\(error). Exiting dSYM conversion process.")
            throw SymbolToolError.failedToConvert
        }
    }
    if debug { print("Parsed mapFiles: \(mapURLs)") }

    // Zip up all map files produced by symbol processing.
    guard let tempDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        throw SymbolToolError.failedToConvert
    }
    
    let tempDirURL = tempDir.appendingPathComponent("\(UUID())")
    
    try fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    // move files in mapURLs into a temporary directory
    for mapFile in mapURLs {
        let newURL = tempDirURL.appendingPathComponent(mapFile.lastPathComponent)
        try fileManager.moveItem(at: mapFile, to: newURL)
    }

    // Now that the map files are in tempDirURL dir lets zip it up.
    let coordinator = NSFileCoordinator()
    var zipError: NSError?
    var archiveUrl: URL?

    coordinator.coordinate(readingItemAt: tempDirURL, options: .forUploading, error: &zipError) { zipURL in
        do {
            let temporaryURL =  tempDirURL.appendingPathComponent("mapArchive.zip")
            try fileManager.moveItem(at: zipURL, to: temporaryURL)
            archiveUrl = temporaryURL

            if let archiveUrl = archiveUrl {
                // Now that we have archiveUrl with the combined map files zipped up, upload the map file.
                let mapUploadResult = try uploadFile(archiveUrl.path, apiKey, url, false)
                if mapUploadResult == "201" {
                    print("Successfully uploaded map: \(archiveUrl.path)")
                }
                else {
                    print("*** Failed w/ error: \(mapUploadResult ?? "NO ERROR") when upload \(archiveUrl.path)")
                }

                // Remove moved map file and zipped map file and temporary folder.
                try fileManager.removeItem(at: tempDirURL)
            }
        } catch {
            print(error)
        }
    }
}

func processSymbolsOutput(_ symbolsOutput: String, _ key: String, _ value: String) throws -> URL {
    let vmAddressOffset = 8
    let dwarfAddressOffset = 12
    let functionOffset = 16
    let sourceLineOffset = 20

    var vmAddresses = [String]()
    var symbols = [String: String]()

    if debug { print("Processing symbols output...") }

    let lines = symbolsOutput.split(whereSeparator: \.isNewline)
    var currentFunction = ""
    for line in lines where !line.isEmpty {
        let whitespaceEndIndex = line.firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: .whitespaces) })
        let whitespaceCount: Int
        if let whitespaceEndIndex = whitespaceEndIndex {
            whitespaceCount = line.distance(from: line.startIndex, to: whitespaceEndIndex)
        }
        else {
            whitespaceCount = 0
        }
        let strippedLine = line.trimmingCharacters(in: .whitespaces)
        switch whitespaceCount {
        case vmAddressOffset:
            let vmAddress = try parseVmAddress(strippedLine)
            vmAddresses.append(vmAddress)
        case dwarfAddressOffset:
            if let dwarfSymbol = try parseDwarf(strippedLine) {
                symbols[dwarfSymbol.0] = dwarfSymbol.1
            }
        case functionOffset:
            let funcSymbol = try parseFunction(strippedLine)
            // Update the current function being parsed. This is used when constructing source line symbols.
            currentFunction = funcSymbol.1
            symbols[funcSymbol.0] = funcSymbol.1
        case sourceLineOffset:
            let sourceLineSymbol = try parseSourceLine(strippedLine, currentFunction)
            symbols[sourceLineSymbol.0] = sourceLineSymbol.1
        default:
            break
        }
    }
    if debug { print("Successfully processed symbols output. COUNT: \(vmAddresses.count) VM, \(symbols.count) SYM") }

    var mapFileContents = ""
    mapFileContents.append("# uuid \(key.uppercased())\n")
    mapFileContents.append("# architecture \(value)\n")
    // Add sorted vmAddresses
    for vmAddress in vmAddresses.sorted() {
        let vmAddrLine = "# vmaddr \(vmAddress)\n"
        mapFileContents.append(vmAddrLine)
    }
    // Add sorted symbols
    for key in symbols.keys.sorted() {
        if let symbolValue = symbols[key] {
            let symbolLine = "\(key) \(symbolValue)\n"
            mapFileContents.append(symbolLine)
        }
    }
    // Now that the map file contents are in mapFileContents. Write it out to map file in the caches directory.
    guard let tempDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        throw SymbolToolError.failedToConvert
    }
    
    let fileURL = tempDir.appendingPathComponent("\(key).map")
    do {
        try mapFileContents.write(to: fileURL, atomically: false, encoding: .utf8)
        if debug { print("Map file successfully saved to \(fileURL)") }
        return fileURL
    } catch {
        print(error)
        throw SymbolToolError.failedToConvert
    }
}

// dSYM Parsing utilities
func parseVmAddress(_ line: String) throws -> String {
    guard let vmAddress = line.components(separatedBy: " ").first?.uppercased() else {
        print("Found invalid vm address. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    return padHex(vmAddress)
}

func parseDwarf(_ line: String) throws -> (String, String)? {
    guard let closeParen = line.firstIndex(of: ")") else {
        print("Found invalid DWARF symbol. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    let closeParenIndex = line.index(closeParen, offsetBy: 2)
    guard let openParen = line.firstIndex(of: "(") else {
        print("Found invalid DWARF symbol. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    let openParenIndex = line.index(openParen, offsetBy: 0)
    let symbolString = line[closeParenIndex...].trimmingCharacters(in: .whitespaces)

    guard symbolString.range(of: "__DWARF") != nil else {
        return nil
    }
    let returnKey = padHex(String(line[...openParenIndex]))
    guard let returnValue = symbolString.components(separatedBy: " ").last else {
        print("Found invalid DWARF symbol. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    return (returnKey, returnValue)
}

func parseFunction(_ line: String) throws -> (String, String) {
    guard let closeParen = line.firstIndex( of: ")"),
          let openParen = line.firstIndex( of: "(") else {
        print("Found invalid FUNCTION symbol. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    let closeParenIndex = line.index(closeParen, offsetBy: 1)
    let openParenIndex = line.index(openParen, offsetBy: 0)
    var currentFunction = ""
    if let bracket = line.range(of: " [") {
        let bracketIndex = line.index(bracket.lowerBound, offsetBy: 0)
        currentFunction = String(line[closeParenIndex...bracketIndex])
    }
    else {
        currentFunction = String(line[closeParenIndex...]).trimmingCharacters(in: .whitespaces) + " "
    }

    return (padHex(String(line[...openParenIndex])), currentFunction)
}

func parseSourceLine(_ line: String, _ currentFunction: String) throws -> (String, String) {
    let lineSplit = line.components(separatedBy: " ").filter { !$0.isEmpty }
    guard lineSplit.count > 3 else {
        print("Found invalid SOURCE LINE symbol. Exiting map file conversion.")
        throw SymbolToolError.failedToConvert
    }
    let sourceString = "\(currentFunction.trimmingCharacters(in: .whitespaces)) (\(lineSplit[3]))"

    return (padHex(lineSplit[0]), sourceString)
}

func padHex(_ hexString: String) -> String {
     let subHexString = String(hexString.dropFirst(2))
     let filledSubHexString = subHexString.padding(toLength: 16, withPad: "0", startingAt: 0)
     return "0x\(filledSubHexString)"
 }

// Networking via curl
func uploadFile(_ path: String, _ apiKey: String, _ url: String, _ isDsym: Bool) throws -> String? {
    var resultFromCurl: String? = nil
    do {
        let command = "curl --retry 3 --write-out %{http_code} --silent --output /dev/null -F \(isDsym ? "dsym" : "upload")=@\"\(path)\" -H \"x-app-license-key: \(apiKey)\" \(url)/\(isDsym ? "symbol" : "map")"
        if debug { print("Executing $ \(command)") }
        resultFromCurl = try shell(command)
    } catch {
        print("curl \(error). Exiting upload process.")
        throw SymbolToolError.failedToUpload
    }

    return resultFromCurl
}

// Shell Utilities
func shell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil
    try task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    return output
}

// String Utilities
func parseRegionFromApiKey(_ key: String) -> String? {
    let range = NSRange(location: 0, length: key.utf16.count)
    let regex = try? NSRegularExpression(pattern: "^.*?x")
    if let regionMatch = regex?.firstMatch(in: key, options: [], range: range), regionMatch.numberOfRanges > 0 {
        if let swiftRange = Range(regionMatch.range(at: 0), in: key) {
            let regionString = String(key[swiftRange]).trimmingTrailingXs()
            return "https://mobile-symbol-upload.\(regionString).nr-data.net"
        }
    }
    return nil
}

extension String {
   func trimmingTrailingXs() -> String {
       guard let index = lastIndex(where: { String($0) != "x" }) else {
            return self
        }
        return String(self[...index])
    }
}
