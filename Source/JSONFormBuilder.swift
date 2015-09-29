//
//  JSONFormBuilder.swift
//  edX
//
//  Created by Michael Katz on 9/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation


protocol FormData {
    func valueForField(key: String) -> String?
}

protocol FormCell {
    func applyData(field: JSONFormBuilder.Field, data: FormData)
}

class JSONFormBuilder {
    
    class OptionsCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.OptionsCell"
        
        func applyData(field: Field, data: FormData) {
            let titleTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let valueTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
            
            let formatStr = "%@:"
            let title = NSString(format: formatStr, field.title!) as String
            let titleAttrStr = titleTextStyle.attributedStringWithText(title)
            
            let value = data.valueForField(field.name) ?? ""
            let valueAttrStr = valueTextStyle.attributedStringWithText(value)
            
            textLabel?.attributedText = NSAttributedString.joinInNaturalLayout([titleAttrStr, valueAttrStr])
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    static func registerCells(tableView: UITableView) {
        tableView.registerClass(OptionsCell.self, forCellReuseIdentifier: OptionsCell.Identifier)
    }
    
    enum FieldType: String {
        case Select = "select"
        
        init?(jsonVal: String?) {
            if let str = jsonVal {
                if let type = FieldType(rawValue: str) {
                    self = type
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        var identifier: String {
            switch self {
            case .Select:
                return OptionsCell.Identifier
            }
        }
    }
    
    struct Field {
        let type: FieldType?
        let name: String
        var identifier: String? { return type?.identifier ?? OptionsCell.Identifier} //TODO: temp
        let title: String?
        
        init (json: JSON) {
            type = FieldType(jsonVal: json["type"].string)
            title = json["label"].string
            name = json["name"].string!
        }
    }
    
    let json: JSON
    lazy var fields: [Field]? = {
        return self.json["fields"].array?.map { return Field(json: $0) }
        }()
    
    init?(jsonFile: String) throws {
        if let filePath = NSBundle(forClass: self.dynamicType).pathForResource(jsonFile, ofType: "json") {
            if let data = NSData(contentsOfFile: filePath) {
                var error: NSError?
                json = JSON(data: data, error: &error)
                if error != nil { throw error! }
            } else {
                json = JSON(NSNull())
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
            }
        }  else {
            json = JSON(NSNull())
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
    }
    
    init(json: JSON) {
        self.json = json
    }
    
//    private func parseJSON() {
//        json["fields"].array
//    }
// 
    
}