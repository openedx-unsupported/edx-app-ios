//
//  OEXVideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

protocol VideoTranscriptDelegate {
    func didSelectSubtitleAtInterval(time: NSTimeInterval)
}

private func setupTable(tableView: UITableView) {
    tableView.registerClass(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
    tableView.separatorColor = UIColor.clearColor()
    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
    
}

@objc class OEXVideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    let transcriptTableView = UITableView(frame: CGRectZero, style: .Plain)
    var transcriptArray = [AnyObject]()
    var selectedIndex = 0
    var delegate : VideoTranscriptDelegate?
    
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
        cell.setTranscriptText(self.transcriptArray[indexPath.row]["kText"] as? String, highlighted: indexPath.row == selectedIndex)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.didSelectSubtitleAtInterval(self.transcriptArray[indexPath.row]["kStart"] as! NSTimeInterval)
    }
    
    //MARK: - OEXVideoTranscriptDelegate methods
    
    func updateTranscript(transcript: [AnyObject]) {
        if transcript.count > 0 {
            dispatch_async(dispatch_get_main_queue(), { 
                self.transcriptArray = transcript
                self.transcriptTableView.reloadData()
                self.transcriptTableView.hidden = false
            })
        }
    }
    
    func highlightSubtitleForTime(time: NSTimeInterval?) {
        if let index = self.transcriptArray.indexOf({ time >= $0["kStart"] as? Double && time <= $0["kEnd"] as? Double }) {
            if index != self.selectedIndex {
                self.selectedIndex = index
                self.transcriptTableView.reloadData()
                self.transcriptTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
            }
        }
    }
}

class VideoTranscriptTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "VideoTranscriptCell"
    
    let titleLabel = UILabel(frame: CGRectZero)
    
    internal var standardTitleStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: OEXStyles.sharedStyles().primaryBaseColor())
        titleLabel.lineBreakMode = .ByWordWrapping
        return style
    }
    
    internal var highlightedTitleStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
        titleLabel.lineBreakMode = .ByWordWrapping
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 0
        titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds)
        self.addSubview(titleLabel)
        self.titleLabel.snp_remakeConstraints { make in
            make.left.equalTo(self.snp_left).offset(20.0)
            make.right.equalTo(self.snp_right).offset(-20.0)
            make.top.equalTo(self.snp_top).offset(10.0)
            make.bottom.equalTo(self.snp_bottom).offset(-10.0)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func setTranscriptText(text: String? , highlighted: Bool) {
        if !highlighted {
            titleLabel.attributedText = standardTitleStyle.attributedStringWithText(text)
        }
        else{
            titleLabel.attributedText = highlightedTitleStyle.attributedStringWithText(text)
        }
    }
}
