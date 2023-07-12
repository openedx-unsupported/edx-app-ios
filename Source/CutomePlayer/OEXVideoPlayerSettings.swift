//
//  VideoPlayerSettings.swift
//  edX
//
//  Created by Michael Katz on 9/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let cellId = "CustomCell"
let captionLanguageNone = "none"

public typealias RowType = (title: String, value: Any)
public struct OEXVideoPlayerSetting {
    let title: String
    let rows: [RowType]
    let isSelected: (_ row: Int) -> Bool
    let callback: (_ value: Any)->()
}

protocol VideoPlayerSettingsDelegate: AnyObject {
    func showSubSettings(chooser: UIAlertController)
    func setCaption(language: String)
    func setPlaybackSpeed(speed: OEXVideoSpeed)
    func videoInfo() -> OEXVideoSummary?
}

private func setupTable(table: UITableView) {
    table.layer.cornerRadius = 10
    table.layer.shadowColor = UIColor.black.cgColor
    table.layer.shadowRadius = 1.0
    table.layer.shadowOffset = CGSize(width: 1, height: 1)
    table.layer.shadowOpacity = 0.8
    table.separatorInset = .zero
    
    table.register(UINib(nibName: "OEXClosedCaptionTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
}

class VideoPlayerSettings : NSObject {
    
    let optionsTable: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    weak var delegate: VideoPlayerSettingsDelegate?
    var settings: [OEXVideoPlayerSetting]  {
        get {
            self.updateMargins() //needs to be done here because the table loads the data too soon otherwise and it's nil
            let rows:[RowType] = [("0.25x",  OEXVideoSpeed.xxSlow), ("0.5x",  OEXVideoSpeed.xSlow), ("0.75x",  OEXVideoSpeed.slow), ("1.0x", OEXVideoSpeed.default), ("1.25x", OEXVideoSpeed.fast), ("1.5x", OEXVideoSpeed.xFast), ("1.75x", OEXVideoSpeed.xxFast), ("2.0x", OEXVideoSpeed.xxxFast)]
            let speeds = OEXVideoPlayerSetting(title: Strings.videoSettingPlaybackSpeed, rows:rows , isSelected: { (row) -> Bool in
                var selected = false
                let savedSpeed = OEXInterface.getCCSelectedPlaybackSpeed()
                let speed = rows[row].value as! OEXVideoSpeed
                
                selected = savedSpeed == speed
    
                return selected
                }) {[weak self] value in
                    let speed = value as! OEXVideoSpeed
                    self?.delegate?.setPlaybackSpeed(speed: speed)
            }
    
            if let transcripts: [String: String] = self.delegate?.videoInfo()?.transcripts as? [String: String] {
                var rows = [RowType]()
                for lang: String in transcripts.keys {
                    let locale = NSLocale(localeIdentifier: lang)
                    if let displayLang: String = locale.displayName(forKey: NSLocale.Key.languageCode, value: lang) {
                        let item: RowType = (title: displayLang, value: lang)
                        rows.append(item)
                    }
                }
                
                if !rows.isEmpty {
                    rows.append(RowType(title: Strings.none, value: captionLanguageNone))
                }
    
                let cc = OEXVideoPlayerSetting(title: Strings.videoSettingClosedCaptions, rows: rows, isSelected: { (row) -> Bool in
                    var selected = false
                    
                    var selectedLanguage = OEXInterface.getCCSelectedLanguage() ?? captionLanguageNone
                    if selectedLanguage.isEmpty {
                        selectedLanguage = captionLanguageNone
                    }
                    let lang = rows[row].value as? String ?? captionLanguageNone
                    selected = selectedLanguage == lang
                    return selected
                }) {[weak self] value in
                    self?.delegate?.setCaption(language: value as? String ?? "")
                }
                return [cc, speeds]
            } else {
                return [speeds]
            }
        }
    }
    
    func updateMargins() {
        optionsTable.layoutMargins = .zero
    }
    
    override init() {
        super.init()
        optionsTable.dataSource = self
        optionsTable.delegate = self
        setupTable(table: optionsTable)
    }
}

extension VideoPlayerSettings: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! OEXClosedCaptionTableViewCell
        cell.selectionStyle = .none
        
        cell.lbl_Title?.font = OEXStyles.shared().regularFont(ofSize: 12)
        cell.lbl_Title?.textColor = OEXStyles.shared().neutralBlack()
        cell.viewDisable?.backgroundColor = OEXStyles.shared().neutralWhiteT()
        cell.layoutMargins = .zero
        cell.backgroundColor = OEXStyles.shared().neutralWhiteT()
     
        let setting = settings[indexPath.row]
        cell.lbl_Title?.text = setting.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSetting = settings[indexPath.row]
        
        let alert = UIAlertController(title: selectedSetting.title, message: nil, preferredStyle: .actionSheet)
        
        for (i, row) in selectedSetting.rows.enumerated() {
            var title = row.title
            if selectedSetting.isSelected(i) {
                //Can't use font awesome here
                title = NSString(format: Strings.videoSettingSelected as NSString, row.title) as String

            }

            alert.addAction(UIAlertAction(title: title, style:.default, handler: { _ in
                selectedSetting.callback(row.value)
            }))
        }
        alert.addCancelAction()
        delegate?.showSubSettings(chooser: alert)
    }
}

