//
//  OEXVideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

protocol OEXVideoTranscriptDelegate {
    func didUpdateTranscript(transcript: [[String: AnyObject]])
}

private func setupTable(tableView: UITableView) {
    tableView.separatorInset = UIEdgeInsetsZero
    tableView.registerClass(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
}

@objc class OEXVideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource, OEXVideoTranscriptDelegate {
    
    let transcriptTableView = UITableView(frame: CGRectZero, style: .Plain)
    var transcriptArray = [[String: AnyObject]]()
    
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
        
        cell.titleLabel.text = self.transcriptArray[indexPath.row]["kText"] as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //MARK: - OEXVideoTranscriptDelegate methods
    
    func didUpdateTranscript(transcript: [[String : AnyObject]]) {
        self.transcriptArray = transcript
        self.transcriptTableView.reloadData()
    }
}

class VideoTranscriptTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "VideoTranscriptCell"
    
    let titleLabel = UILabel(frame: CGRectZero)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        self.titleLabel.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.left.equalTo(self.snp_leftMargin)
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
}
