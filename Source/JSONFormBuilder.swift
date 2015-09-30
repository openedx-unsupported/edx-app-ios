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
    func setValue(value: String?, key: String)
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
            
//            let value = "let courseID : String\n    let environment : Environment\n    let webView : UIWebView\n    let loadController : LoadStateViewController\n    let handouts : BackedStream<String> = BackedStream()\n    \n    init(environment : Environment, courseID : String) {\n        self.environment = environment\n        self.courseID = courseID\n        self.webView = UIWebView()\n        self.loadController = LoadStateViewController(styles: self.environment.styles)\n        \n        super.init(nibName: nil, bundle: nil)\n    }\n\n    required public init?(coder aDecoder: NSCoder) {\n        fatalError(\"init(coder:) has not been implemented\")\n    }\n    \n    override public func viewDidLoad() {\n        super.viewDidLoad()\n        \n        loadController.setupInController(self, contentView: webView)\n        addSubviews()\n        setConstraints()\n        setStyles()\n        webView.delegate = self\n        loadHandouts()\n    }\n    \n    private func addSubviews() {\n        view.addSubview(webView)\n    }\n    \n    private func setConstraints() {\n        webView.snp_makeConstraints { (make) -> Void in\n            make.edges.equalTo(self.view)\n        }\n    }"
            let value = data.valueForField(field.name) ?? ""
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
        
        let instructions: String?
        let subInstructions: String?
        let options: [String: JSON]?
        
        init (json: JSON) {
            type = FieldType(jsonVal: json["type"].string)!
            title = json["label"].string
            name = json["name"].string!
            
            instructions = json["instructions"].string
            subInstructions = json["sub_instructions"].string
            options = json["options"].dictionary
        }
        
        func takeAction(data: FormData, controller: UIViewController) {
            switch type {
            case .Select:
                let newC = JSONFormTableViewController()
                var titles = [String]()
                
                if let rangeMin:Int = options?["range_min"]?.int, rangeMax:Int = options?["range_max"]?.int {
                    let range = rangeMin...rangeMax
                    titles = range.map { String($0)} .reverse()
                }
                
                var defaultRow = -1
                
                let allowsNone = options?["allows_none"]?.bool ?? false
                if allowsNone {
                    titles.insert("--", atIndex: 0)
                    defaultRow = 0
                }
                
                if let alreadySetValue = data.valueForField(name) {
                    defaultRow = titles.indexOf(alreadySetValue) ?? 0
                }
                
                let dataSource = DataSource(titles: titles)
                dataSource.selectedIndex = defaultRow
                
                newC.dataSource = dataSource
                newC.title = title
                newC.instructions = instructions
                newC.subInstructions = subInstructions
                
                newC.doneChoosing = { value in
                    if allowsNone && value != nil && value! == "--" {
                        data.setValue(nil, key: self.name)
                    } else {
                        data.setValue(value, key: self.name)
                    }
                }
                
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

private class JSONFormTableSelectionCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        tintColor = OEXStyles.sharedStyles().utilitySuccessBase()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class JSONFormTableViewController: UITableViewController {
    var dataSource: DataSource?
    var instructions: String?
    var subInstructions: String?
    
    var doneChoosing: ((value:String?)->())?
    
    private func makeAndInstallHeader() {
        if let instructions = instructions {
            let headerView = UIView()
            headerView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
            
            let instructionStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let headerStr = instructionStyle.attributedStringWithText(instructions).mutableCopy() as! NSMutableAttributedString
            
            if let subInstructions = subInstructions {
                let style = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
                let subStr = style.attributedStringWithText("\n" + subInstructions)
                headerStr.appendAttributedString(subStr)
            }
            
            let label = UILabel()
            label.attributedText = headerStr
            label.numberOfLines = 0
            
            headerView.addSubview(label)
            label.snp_makeConstraints(closure: { (make) -> Void in
                make.top.equalTo(headerView.snp_topMargin)
                make.bottom.equalTo(headerView.snp_bottomMargin)
                make.leading.equalTo(headerView.snp_leadingMargin)
                make.trailing.equalTo(headerView.snp_trailingMargin)
            })
            
            let size = label.sizeThatFits(CGSizeMake(240, CGFloat.max))
            headerView.frame = CGRect(origin: CGPointZero, size: size)
            
            tableView.tableHeaderView = headerView
        }
    }
    
    private override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(JSONFormTableSelectionCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        makeAndInstallHeader()
    }

    private override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil { //removing from the hierarchy
            doneChoosing?(value: dataSource?.selectedItem)
        }
    }
    
}

class DataSource : NSObject, UITableViewDataSource, UITableViewDelegate {
    let titles: [String]
    var selectedIndex: Int = -1
    var selectedItem: String? {
        return selectedIndex < titles.count && selectedIndex >= 0 ? titles[selectedIndex] : nil
    }
    
    init(titles: [String]) {
        self.titles = titles
        super.init()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let oldIndexPath = selectedIndex
        selectedIndex = indexPath.row
        
        var rowsToRefresh = [indexPath]
        if oldIndexPath != -1 {
            rowsToRefresh.append(NSIndexPath(forRow: oldIndexPath, inSection: indexPath.section))
        }
        
        tableView.reloadRowsAtIndexPaths(rowsToRefresh, withRowAnimation: .Automatic)
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.accessoryType = indexPath.row == selectedIndex ? .Checkmark : .None
    }
}