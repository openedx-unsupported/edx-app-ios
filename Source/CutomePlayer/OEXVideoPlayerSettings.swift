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

struct OEXVideoPlayerSetting {
    let title: String
    let rows: [String]
}


@objc class OEXVideoPlayerSettings : NSObject {
    
    let optionsTable: UITableView = UITableView(frame: CGRectZero, style: .Plain)
    let settings: [OEXVideoPlayerSetting]
    
    override init() {
        //TODO: has transcripts
        settings = [OEXVideoPlayerSetting]() //TODO:     self.arr_SettingOptions = [[NSMutableArray alloc] initWithObjects:@"Closed Captions", @"Video Speed", nil];


        super.init()
        
        optionsTable.dataSource = self
        optionsTable.delegate = self
        optionsTable.layer.cornerRadius = 10
        optionsTable.layer.shadowColor = UIColor.blackColor().CGColor
        optionsTable.layer.shadowRadius = 1.0
        optionsTable.layer.shadowOffset = CGSize(width: 1, height: 1)
        optionsTable.layer.shadowOpacity = 0.8
        optionsTable.separatorInset = UIEdgeInsetsZero
        
        if IS_IOS8() {
            optionsTable.layoutMargins = UIEdgeInsetsZero
        }
        
        optionsTable.registerNib(UINib(nibName: "OEXClosedCaptionTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")

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
        let cellId = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! OEXClosedCaptionTableViewCell
        
        //TODO: put in custom class
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 41.0/255.0, green: 158.0/255.0, blue: 215.0/255.0, alpha: 0.2)
        bgColorView.layer.masksToBounds = true
        cell.selectedBackgroundView = bgColorView
        cell.selectionStyle = .Default
        
        cell.lbl_Title.font = UIFont(name: "OpenSans", size: 12)
        cell.viewDisable.backgroundColor = UIColor.whiteColor()
        if IS_IOS8() {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        cell.backgroundColor = UIColor.whiteColor()
     
        bgColorView.removeFromSuperview()
        
        let setting = settings[indexPath.row]
        cell.lbl_Title.text = setting.title
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedSetting = settings[indexPath.row]
        let chooser = OEXVideoPlayerSettingsChooseTable(selectedSetting)
    }
}



@objc class OEXVideoPlayerSettingsChooseTable: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let setting: OEXVideoPlayerSetting
    let table = UITableView(frame: CGRectZero, style: .Plain)
    
    
    init(setting: OEXVideoPlayerSetting) {
        self.setting = setting;
        
        //TODO:setuptable
        table.registerNib(UINib(nibName: "OEXClosedCaptionTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")

    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return setting.rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellId = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! OEXClosedCaptionTableViewCell
        
        //TODO: if selected row is selected speed or cc list, add bgcolorview, else remove it
        cell.lbl_Title.text = setting.rows[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        view.backgroundColor = UIColor(red: 226.0/255.0, green: 227.0/255.0, blue: 229.0/255.0, alpha: 1.0)
        
        let chapTitle = UILabel(frame: CGRect(x: 10, y: 0, width: 280, height: 44))
        chapTitle.text = setting.title
        chapTitle.font = UIFont(name: "OpenSans", size: 12)
        chapTitle.textColor = UIColor.blackColor()
        view.addSubview(chapTitle)
        
        return view
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}