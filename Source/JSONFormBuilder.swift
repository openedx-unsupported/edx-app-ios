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
            accessoryType = .DisclosureIndicator
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class TextAreaCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.TextAreaCell"
        
        func applyData(field: Field, data: FormData) {
            let titleTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let valueTextStyle = OEXMutableTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
            valueTextStyle.lineBreakMode = .ByWordWrapping
            
            let formatStr = "%@:"
            let title = NSString(format: formatStr, field.title!) as String
            let titleAttrStr = titleTextStyle.attributedStringWithText(title)
            
            let value = "let courseID : String\n    let environment : Environment\n    let webView : UIWebView\n    let loadController : LoadStateViewController\n    let handouts : BackedStream<String> = BackedStream()\n    \n    init(environment : Environment, courseID : String) {\n        self.environment = environment\n        self.courseID = courseID\n        self.webView = UIWebView()\n        self.loadController = LoadStateViewController(styles: self.environment.styles)\n        \n        super.init(nibName: nil, bundle: nil)\n    }\n\n    required public init?(coder aDecoder: NSCoder) {\n        fatalError(\"init(coder:) has not been implemented\")\n    }\n    \n    override public func viewDidLoad() {\n        super.viewDidLoad()\n        \n        loadController.setupInController(self, contentView: webView)\n        addSubviews()\n        setConstraints()\n        setStyles()\n        webView.delegate = self\n        loadHandouts()\n    }\n    \n    private func addSubviews() {\n        view.addSubview(webView)\n    }\n    \n    private func setConstraints() {\n        webView.snp_makeConstraints { (make) -> Void in\n            make.edges.equalTo(self.view)\n        }\n    }"
            // data.valueForField(field.name) ?? ""
            let valueAttrStr = valueTextStyle.attributedStringWithText(value)
            
            textLabel?.numberOfLines = 0
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
        tableView.registerClass(TextAreaCell.self, forCellReuseIdentifier: TextAreaCell.Identifier)
    }
    
    enum FieldType: String {
        case Select = "select"
        case TextArea = "textarea"
        
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
            case .TextArea:
                return TextAreaCell.Identifier
            }
        }
    }
    
    struct Field {
        let type: FieldType
        let name: String
        var identifier: String? { return type.identifier }
        let title: String?
        
        let instruction: String?
        let subInstruction: String?
        
        init (json: JSON) {
            type = FieldType(jsonVal: json["type"].string)!
            title = json["label"].string
            name = json["name"].string!
            
            instruction = json["instructions"].string
            subInstruction = json["sub_instructions"].string
        }
        
        func takeAction(controller: UIViewController) {
            switch type {
            case .Select:
                let newC = JSONFormTableViewController()
                newC.dataSource = DataSource()
                newC.title = title
                newC.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
                newC.tableView.dataSource = newC.dataSource
                controller.navigationController?.pushViewController(newC, animated: true)

            case .TextArea:
                print("")
            }
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
    
}

private class JSONFormTableViewController : UITableViewController {
    var dataSource: UITableViewDataSource?
}

class DataSource : NSObject, UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = String(indexPath.row)
        return cell
    }
}