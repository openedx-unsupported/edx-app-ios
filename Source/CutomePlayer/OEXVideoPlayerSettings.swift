//
//  OEXVideoPlayerSettings.swift
//  edX
//
//  Created by Michael Katz on 9/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

func IS_IOS8() -> Bool {
    return (UIDevice.currentDevice().systemVersion as NSString).integerValue >= 8
}

let cellId = "CustomCell"

typealias RowType = (title: String, value: Any)
struct OEXVideoPlayerSetting {
    let title: String
    let rows: [RowType]
    let callback: (row: Int)->()
}

@objc protocol OEXVideoPlayerSettingsDelegate {
    func showSubSettings(chooser: UIActionSheet)
    func setCaption(language: String)
    func setPlaybackSpeed(speed: Float)
    func videoInfo() -> OEXVideoSummary
}


func setupTable(table: UITableView) {
    table.layer.cornerRadius = 10
    table.layer.shadowColor = UIColor.blackColor().CGColor
    table.layer.shadowRadius = 1.0
    table.layer.shadowOffset = CGSize(width: 1, height: 1)
    table.layer.shadowOpacity = 0.8
    table.separatorInset = UIEdgeInsetsZero
    
    table.registerNib(UINib(nibName: "OEXClosedCaptionTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
}

@objc class OEXVideoPlayerSettings : NSObject {
    
    let optionsTable: UITableView = UITableView(frame: CGRectZero, style: .Plain)
    lazy var settings: [OEXVideoPlayerSetting] = {
        self.updateMargins() //needs to be done here because the table loads the data too soon otherwise and it's nil
        
        let speeds = OEXVideoPlayerSetting(title: "Video Speed", rows: [("0.5x",  0.5), ("1.0x", 1.0), ("1.5x", 1.5), ("2.0x", 2.0)]) {row in
            let value = Float(self.selectedSetting!.rows[row].value as! Double)
            self.delegate?.setPlaybackSpeed(value)
        }
        
        if let transcripts: [String: String] = self.delegate?.videoInfo().transcripts as? [String: String] {
            var rows = [RowType]()
            for lang: String in transcripts.keys {
                let locale = NSLocale(localeIdentifier: lang)
                let displayLang: String = locale.displayNameForKey(NSLocaleLanguageCode, value: lang)!
                let item: RowType = (title: displayLang, value: lang)
                rows.append(item)
            }
            
            let cc = OEXVideoPlayerSetting(title: "Closed Captions", rows: rows) {row in
                let value = self.selectedSetting!.rows[row].value as! String
                self.delegate?.setCaption(value)
            }
            return [cc, speeds]
        } else {
            return [speeds]
        }
    }()
    weak var delegate: OEXVideoPlayerSettingsDelegate?
    var selectedSetting: OEXVideoPlayerSetting?

    func updateMargins() {
        if IS_IOS8() {
            optionsTable.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    init(delegate: OEXVideoPlayerSettingsDelegate, videoInfo: OEXVideoSummary) {
        self.delegate = delegate

        super.init()
        
        optionsTable.dataSource = self
        optionsTable.delegate = self
        setupTable(optionsTable)
    }
}

extension OEXVideoPlayerSettings: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! OEXClosedCaptionTableViewCell
        cell.selectionStyle = .None
        
        cell.lbl_Title.font = UIFont(name: "OpenSans", size: 12)
        cell.viewDisable.backgroundColor = UIColor.whiteColor()
        if IS_IOS8() {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        cell.backgroundColor = UIColor.whiteColor()
     
        let setting = settings[indexPath.row]
        cell.lbl_Title.text = setting.title
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedSetting = settings[indexPath.row]
        let actionSheet = UIActionSheet(title: selectedSetting!.title, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)

        for row in selectedSetting!.rows {
            actionSheet.addButtonWithTitle(row.title)
        }
        delegate?.showSubSettings(actionSheet)
    }
}


extension OEXVideoPlayerSettings: UIActionSheetDelegate {
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex {
            selectedSetting?.callback(row: buttonIndex - 1)
        }
    }
}
