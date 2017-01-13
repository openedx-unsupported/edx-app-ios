//
//  VideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

protocol VideoTranscriptDelegate {
    func didSelectSubtitleAtInterval(time: NSTimeInterval)
}

class VideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource{
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, ReachabilityProvider>
    
    let transcriptTableView = UITableView(frame: CGRectZero, style: .Plain)
    var transcriptArray = [AnyObject]()
    let environment : Environment
    var delegate : VideoTranscriptDelegate?
    
    /*
     Maintain the cell index highlighted currently
     */
    var highlightedIndex = 0
    
    /*
     Flag to toggle if tableview has been dragged in the last few seconds
     */
    var isTableDragged : Bool = false
    
    /*
     Timer to reset the isTableDragged flag so automatic scrolling can kick back in
     */
    var draggingTimer = NSTimer()
    
    /*
     Delay after which automatic scrolling should kick back in
     */
    let dragDelay : NSTimeInterval = 5.0
    
    init(environment : Environment) {
        self.environment = environment
        super.init()
        setupTable(transcriptTableView)
        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
    }
    
    private func setupTable(tableView: UITableView) {
        tableView.registerClass(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
        tableView.separatorColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.hidden = true
    }
    
    //MARK: - UITableview methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VideoTranscriptTableViewCell.cellIdentifier) as! VideoTranscriptTableViewCell
        cell.applyStandardSeparatorInsets()
        cell.setTranscriptText(transcriptArray[indexPath.row][CLVideoPlayerkText] as? String, highlighted: indexPath.row == highlightedIndex)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.didSelectSubtitleAtInterval(transcriptArray[indexPath.row][CLVideoPlayerkStart] as! NSTimeInterval)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isTableDragged = true
        draggingTimer.invalidate()
        draggingTimer = NSTimer.scheduledTimerWithTimeInterval(dragDelay, target: self, selector: #selector(invalidateDragging), userInfo: nil, repeats: false)
    }
    
    //MARK: -
    
    func updateTranscript(transcript: [AnyObject]) {
        if transcript.count > 0 {
            transcriptArray = transcript
            transcriptTableView.reloadData()
            transcriptTableView.hidden = false
        }
    }
    
    func highlightSubtitleForTime(time: NSTimeInterval?) {
        if let index = getTranscriptIndexForTime(time) where index != highlightedIndex{
            highlightedIndex = index
            transcriptTableView.reloadData()
            if !isTableDragged {
                transcriptTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
            }
        }
    }
    
    func getTranscriptIndexForTime(time: NSTimeInterval?) -> Int? {
        return transcriptArray.indexOf({ time >= $0[CLVideoPlayerkStart] as? Double && time <= $0[CLVideoPlayerkEnd] as? Double })
    }
    
    func invalidateDragging(){
        isTableDragged = false
    }
}
