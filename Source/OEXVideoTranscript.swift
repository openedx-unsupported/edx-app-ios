//
//  OEXVideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

private func setupTable(tableView: UITableView) {
    tableView.registerClass(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
    
    tableView.separatorInset = UIEdgeInsetsZero
    tableView.estimatedRowHeight = 44
    tableView.rowHeight = UITableViewAutomaticDimension
}

@objc class OEXVideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    let transcriptTableView = UITableView(frame: CGRectZero, style: .Plain)
    var transcriptArray = [AnyObject]()
    
    override init() {
        super.init()
        setupTable(transcriptTableView)
        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
        transcriptTableView.reloadData()
        
    }
    
    //MARK: - UITableview methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VideoTranscriptTableViewCell.cellIdentifier) as! VideoTranscriptTableViewCell
        
        cell.layoutMargins = UIEdgeInsetsZero
        cell.backgroundColor = UIColor.whiteColor()
        cell.setTranscriptText(self.transcriptArray[indexPath.row]["kText"] as? String)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //MARK: - OEXVideoTranscriptDelegate methods
    
    func updateTranscript(transcript: [AnyObject]) {
        if transcript.count > 0 {
            self.transcriptArray = transcript
            self.transcriptTableView.reloadData()
            self.transcriptTableView.hidden = false
//            self.transcriptTableView.layoutIfNeeded()
        }
    }
}

class VideoTranscriptTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "VideoTranscriptCell"
    
    let titleLabel = UILabel(frame: CGRectZero)
    
    internal var titleStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
        titleLabel.lineBreakMode = .ByWordWrapping
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 0
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.titleLabel.snp_remakeConstraints { make in
            make.left.equalTo(self.snp_leftMargin)
            make.right.equalTo(self.snp_rightMargin)
            make.top.equalTo(self.snp_topMargin)
            make.bottom.equalTo(self.snp_bottomMargin)
        }
        super.layoutSubviews()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = UIColor.lightGrayColor()
        }
        else {
            self.backgroundColor = UIColor.whiteColor()
        }
    }
    
    func setTranscriptText(text: String?) {
        titleLabel.attributedText = titleStyle.attributedStringWithText(text)
    }
}
