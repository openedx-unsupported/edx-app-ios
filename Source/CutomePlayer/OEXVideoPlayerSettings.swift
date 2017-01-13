//
//  OEXVideoPlayerSettings.swift
//  edX
//
//  Created by Michael Katz on 9/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let cellId = "CustomCell"

private typealias RowType = (title: String, value: Any)
private struct OEXVideoPlayerSetting {
    let title: String
    let rows: [RowType]
    let isSelected: (row: Int) -> Bool
    let callback: (value: Any)->()
}

@objc protocol OEXVideoPlayerSettingsDelegate {
    func showSubSettings(chooser: UIAlertController)
    func setCaption(language: String)
    func setPlaybackSpeed(speed: OEXVideoSpeed)
    func videoInfo() -> OEXVideoSummary
}

private func setupTable(table: UITableView) {
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
    private lazy var settings: [OEXVideoPlayerSetting] = {
        self.updateMargins() //needs to be done here because the table loads the data too soon otherwise and it's nil
        
        let rows:[RowType] = [("0.5x",  OEXVideoSpeed.Slow), ("1.0x", OEXVideoSpeed.Default), ("1.5x", OEXVideoSpeed.Fast), ("2.0x", OEXVideoSpeed.XFast)]
        let speeds = OEXVideoPlayerSetting(title: "Video Speed", rows:rows , isSelected: { (row) -> Bool in
            var selected = false
            let savedSpeed = OEXInterface.getCCSelectedPlaybackSpeed()
            
            let speed = rows[row].value as! OEXVideoSpeed
            
            selected = savedSpeed == speed
            
            return selected
            }) {[weak self] value in
                let speed = value as! OEXVideoSpeed
                self?.delegate?.setPlaybackSpeed(speed)
        }
        
        if let transcripts: [String: String] = self.delegate?.videoInfo().transcripts as? [String: String] {
            var rows = [RowType]()
            for lang: String in transcripts.keys {
                let locale = NSLocale(localeIdentifier: lang)
                let displayLang: String = locale.displayNameForKey(NSLocaleLanguageCode, value: lang)!
                let item: RowType = (title: displayLang, value: lang)
                rows.append(item)
            }
            
            let cc = OEXVideoPlayerSetting(title: "Closed Captions", rows: rows, isSelected: { (row) -> Bool in
                var selected = false
                if let selectedLanguage:String = OEXInterface.getCCSelectedLanguage() {
                    let lang = rows[row].value as! String
                    selected = selectedLanguage == lang
                }
                return selected
            }) {[weak self] value in
                var language : String = value as! String
                if language == OEXInterface.getCCSelectedLanguage() && language != "" {
                    language = ""
                }
                self?.delegate?.setCaption(language)
            }
            return [cc, speeds]
        } else {
            return [speeds]
        }
    }()
    weak var delegate: OEXVideoPlayerSettingsDelegate?

    func updateMargins() {
        optionsTable.layoutMargins = UIEdgeInsetsZero
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
        
        cell.lbl_Title?.font = UIFont(name: "OpenSans", size: 12)
        cell.viewDisable?.backgroundColor = UIColor.whiteColor()
        cell.layoutMargins = UIEdgeInsetsZero
        cell.backgroundColor = UIColor.whiteColor()
     
        let setting = settings[indexPath.row]
        cell.lbl_Title?.text = setting.title
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedSetting = settings[indexPath.row]
        
        let alert = UIAlertController(title: selectedSetting.title, message: nil, preferredStyle: .ActionSheet)
        
        for (i, row) in selectedSetting.rows.enumerate() {
            var title = row.title
            if selectedSetting.isSelected(row: i) {
                //Can't use font awesome here
                title = NSString(format: Strings.videoSettingSelected, row.title) as String

            }

            alert.addAction(UIAlertAction(title: title, style:.Default, handler: { _ in
                selectedSetting.callback(value: row.value)
            }))
        }
        alert.addCancelAction()
        delegate?.showSubSettings(alert)
    }
}

