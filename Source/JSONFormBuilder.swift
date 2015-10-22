//
//  JSONFormBuilder.swift
//  edX
//
//  Created by Michael Katz on 9/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private func equalsCaseInsensitive(lhs: String, _ rhs: String) -> Bool {
    return lhs.caseInsensitiveCompare(rhs) == .OrderedSame
}

/** Model for the built form must allow for reads and updates */
protocol FormData {
    func valueForField(key: String) -> String?
    func displayValueForKey(key: String) -> String?
    func setValue(value: String?, key: String)
}

/** Decorate the cell with the model object */
protocol FormCell  {
    func applyData(field: JSONFormBuilder.Field, data: FormData)
}

private func loadJSON(jsonFile: String) throws -> JSON {
    var js: JSON
    if let filePath = NSBundle.mainBundle().pathForResource(jsonFile, ofType: "json") {
        if let data = NSData(contentsOfFile: filePath) {
            var error: NSError?
            js = JSON(data: data, error: &error)
            if error != nil { throw error! }
        } else {
            js = JSON(NSNull())
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
        }
    }  else {
        js = JSON(NSNull())
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }
    return js
}

/** Function to turn a specialized JSON file (https://openedx.atlassian.net/wiki/display/MA/Profile+Forms) into table rows, with various editor views and view controllers */
class JSONFormBuilder {
    
    /** Show a segmented control from a limited set of options */
    class SegmentCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.SwitchCell"

        let titleLabel = UILabel()
        let descriptionLabel = UILabel()
        let typeControl = UISegmentedControl()
        var values = [String]()
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            contentView.addSubview(titleLabel)
            contentView.addSubview(typeControl)
            contentView.addSubview(descriptionLabel)
            
            titleLabel.textAlignment = .Natural
            
            let selectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralBlackT())
            let unselectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
            typeControl.setTitleTextAttributes(selectedAttributes.attributes, forState: .Selected)
            typeControl.setTitleTextAttributes(unselectedAttributes.attributes, forState: .Normal)
            typeControl.tintColor = OEXStyles.sharedStyles().primaryXLightColor()
            
            descriptionLabel.textAlignment = .Natural
            descriptionLabel.numberOfLines = 2
            descriptionLabel.adjustsFontSizeToFitWidth = true
            descriptionLabel.minimumScaleFactor = 0.5
            
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.top.equalTo(contentView.snp_topMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            typeControl.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp_bottom).offset(6)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
            }
            
            descriptionLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(typeControl.snp_bottom).offset(6)
                make.leading.equalTo(contentView.snp_leadingMargin)
                make.trailing.equalTo(contentView.snp_trailingMargin)
                make.bottom.equalTo(contentView.snp_bottomMargin)
            }
        }
        
        func applyData(field: JSONFormBuilder.Field, data: FormData) {
            let titleStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let descriptionStyle = OEXMutableTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
            descriptionStyle.lineBreakMode = .ByTruncatingTail
            
            titleLabel.attributedText = titleStyle.attributedStringWithText(field.title)
            descriptionLabel.attributedText = descriptionStyle.attributedStringWithText(field.instructions)
            
            if let hint = field.accessibilityHint {
                typeControl.accessibilityHint = hint
            }
            
            values.removeAll(keepCapacity: true)
            typeControl.removeAllSegments()
            if let optionsValues = field.options?["values"]?.arrayObject {
                for valueDict in optionsValues {
                    let title = valueDict["name"] as! String
                    let value = valueDict["value"] as! String
                    typeControl.insertSegmentWithTitle(title, atIndex: values.count, animated: false)
                    values.append(value)
                }

            }
            
            if let val = data.valueForField(field.name), selectedIndex = values.indexOf(val) {
                typeControl.selectedSegmentIndex = selectedIndex
            }

        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    /** Show a cell that provides a long list of options in a new viewcontroller */
    class OptionsCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.OptionsCell"
        
        func applyData(field: Field, data: FormData) {
            let titleTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let valueTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
            
            let title = Strings.formLabel(label: field.title!)
            let titleAttrStr = titleTextStyle.attributedStringWithText(title)
            
            let value = data.displayValueForKey(field.name) ?? ""
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
    
    /** Show an editable text area in a new view */
    class TextAreaCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.TextAreaCell"
        
        func applyData(field: Field, data: FormData) {
            let titleTextStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let valueTextStyle = OEXMutableTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
            valueTextStyle.lineBreakMode = .ByWordWrapping
            
            let title = Strings.formLabel(label: field.title!)
            let titleAttrStr = titleTextStyle.attributedStringWithText(title)
            let value = data.valueForField(field.name) ?? field.placeholder ?? ""
            let valueAttrStr = valueTextStyle.attributedStringWithText(value)
            
            textLabel?.numberOfLines = 0
            textLabel?.attributedText = NSAttributedString.joinInNaturalLayout([titleAttrStr, valueAttrStr])
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            accessoryType = .DisclosureIndicator
        }
    }
    
    /** Add the cell types to the tableview */
    static func registerCells(tableView: UITableView) {
        tableView.registerClass(OptionsCell.self, forCellReuseIdentifier: OptionsCell.Identifier)
        tableView.registerClass(TextAreaCell.self, forCellReuseIdentifier: TextAreaCell.Identifier)
        tableView.registerClass(SegmentCell.self, forCellReuseIdentifier: SegmentCell.Identifier)
    }
    
    /** Fields parsed out of the json. Each field corresponds to it's own row with specialized editor */
    struct Field {
        enum FieldType: String {
            case Select = "select"
            case TextArea = "textarea"
            case Switch = "switch"
            
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
            
            var cellIdentifier: String {
                switch self {
                case .Select:
                    return OptionsCell.Identifier
                case .TextArea:
                    return TextAreaCell.Identifier
                case .Switch:
                    return SegmentCell.Identifier
                }
            }
        }

        //Field Data types Supported by the form builder
        enum DataType : String {
            case StringType = "string"
            case CountryType = "country"
            case LanguageType = "language"
            
            init(_ rawValue: String?) {
                guard let val = rawValue else { self = .StringType; return }                
                switch val {
                case "country":
                    self = .CountryType
                case "language":
                    self = .LanguageType
                default:
                    self = .StringType
                }
            }
        }
        
        let type: FieldType
        let name: String
        var cellIdentifier: String { return type.cellIdentifier }
        let title: String?
        
        let instructions: String?
        let subInstructions: String?
        let accessibilityHint: String?
        let options: [String: JSON]?
        let dataType: DataType
        let defaultValue: String?
        let placeholder: String?
        
        init (json: JSON) {
            type = FieldType(jsonVal: json["type"].string)!
            title = json["label"].string
            name = json["name"].string!
            
            instructions = json["instructions"].string
            subInstructions = json["sub_instructions"].string
            options = json["options"].dictionary
            dataType = DataType(json["data_type"].string)
            defaultValue = json["default"].string
            accessibilityHint = json["accessibility_hint"].string
            placeholder = json["placeholder"].string
        }
        
        private func attributedChooserRow(icon: Icon, title: String, value: String?) -> NSAttributedString {
            let iconStyle = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralXLight())
            let icon = icon.attributedTextWithStyle(iconStyle)
            
            let titleStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let titleAttrStr = titleStyle.attributedStringWithText(title)
            
            let valueStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
            let valAttrString = valueStyle.attributedStringWithText(value)
            
            return  NSAttributedString.joinInNaturalLayout([icon, titleAttrStr, valAttrString])
        }
        
        private func selectAction(data: FormData, controller: UIViewController) {
            let selectionController = JSONFormTableViewController<String>()
            var tableData = [ChooserDatum<String>]()
            
            if let rangeMin:Int = options?["range_min"]?.int, rangeMax:Int = options?["range_max"]?.int {
                let range = rangeMin...rangeMax
                let titles = range.map { String($0)} .reverse()
                tableData = titles.map { ChooserDatum(value: $0, title: $0, attributedTitle: nil) }
            } else if let file = options?["reference"]?.string {
                do {
                    let json = try loadJSON(file)
                    if let values = json.array {
                        tableData = values.map { ChooserDatum(value: $0["value"].string!, title: $0["name"].string, attributedTitle: nil)}
                    }
                } catch {
                    Logger.logError("JSON", "Error parsing JSON: \(error)")
                }
            }
            
            var defaultRow = -1
            
            let allowsNone = options?["allows_none"]?.bool ?? false
            if allowsNone {
                tableData.insert(ChooserDatum(value: "--", title: "--", attributedTitle: nil), atIndex: 0)
                defaultRow = 0
            }
            
            if let alreadySetValue = data.valueForField(name) {
                defaultRow = tableData.indexOf { equalsCaseInsensitive($0.value, alreadySetValue) } ?? defaultRow
            }
            
            if dataType == .CountryType {
                if let id = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String {
                    let countryName = NSLocale.currentLocale().displayNameForKey(NSLocaleCountryCode, value: id)
                    let title = attributedChooserRow(Icon.Country, title: Strings.Profile.currentLocationLabel, value: countryName)
                    
                    tableData.insert(ChooserDatum(value: id, title: nil, attributedTitle: title), atIndex: 0)
                    if defaultRow >= 0 { defaultRow++ }
                }
            } else if dataType == .LanguageType {
                if let id = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String {
                    let languageName = NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value: id)
                    let title = attributedChooserRow(Icon.Comment, title: Strings.Profile.currentLanguageLabel, value: languageName)
                    
                    tableData.insert(ChooserDatum(value: id, title: nil, attributedTitle: title), atIndex: 0)
                    if defaultRow >= 0 { defaultRow++ }
                }
            }
            
            let dataSource = ChooserDataSource(data: tableData)
            dataSource.selectedIndex = defaultRow
            
            
            selectionController.dataSource = dataSource
            selectionController.title = title
            selectionController.instructions = instructions
            selectionController.subInstructions = subInstructions
            
            selectionController.doneChoosing = { value in
                if allowsNone && value != nil && value! == "--" {
                    data.setValue(nil, key: self.name)
                } else {
                    data.setValue(value, key: self.name)
                }
            }
            
            controller.navigationController?.pushViewController(selectionController, animated: true)
        }
        
        /** What happens when the user selects the row */
        func takeAction(data: FormData, controller: UIViewController) {
            switch type {
            case .Select:
               selectAction(data, controller: controller)
            case .TextArea:
                let text = data.valueForField(name)
                let textController = JSONFormBuilderTextEditorViewController(text: text, placeholder: placeholder)
                textController.title = title
                
                textController.doneEditing = { value in
                    if value == "" {
                        data.setValue(nil, key: self.name)
                    } else {
                        data.setValue(value, key: self.name)
                    }
                }
                
                controller.navigationController?.pushViewController(textController, animated: true)
            case .Switch:
                //no action on cell selection - let control in cell handle action
                break;
            }
        }
    }
    
    let json: JSON
    lazy var fields: [Field]? = {
        return self.json["fields"].array?.map { return Field(json: $0) }
        }()

    
    init?(jsonFile: String) {
        do {
            json = try loadJSON(jsonFile)
        } catch {
            json = JSON(NSNull())
            return nil
        }
    }
    
    init(json: JSON) {
        self.json = json
    }
    
}

