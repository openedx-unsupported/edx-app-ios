//
//  VideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

protocol VideoTranscriptDelegate {
    func didSelectSubtitleAtInterval(time: TimeInterval)
}

class VideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource{
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider
    
    let transcriptTableView = UITableView(frame: CGRect.zero, style: .plain)
    var transcriptArray = [AnyObject]()
    let environment : Environment
    var delegate : VideoTranscriptDelegate?
    
    //Maintain the cell index highlighted currently
    var highlightedIndex = 0
    
    //Flag to toggle if tableview has been dragged in the last few seconds
    var isTableDragged : Bool = false
    
    //Timer to reset the isTableDragged flag so automatic scrolling can kick back in
    var draggingTimer = Timer()
    
    //Delay after which automatic scrolling should kick back in
    let dragDelay : TimeInterval = 5.0
    
    init(environment : Environment) {
        self.environment = environment
        super.init()
        setupTable(tableView: transcriptTableView)
        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
    }
    
    private func setupTable(tableView: UITableView) {
        tableView.register(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
        tableView.separatorColor = UIColor.clear
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.isHidden = true
    }
    
    //MARK: - UITableview methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptArray.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoTranscriptTableViewCell.cellIdentifier) as! VideoTranscriptTableViewCell
        cell.applyStandardSeparatorInsets()
        cell.setTranscriptText(text: (transcriptArray[indexPath.row] as? [String: AnyObject])?[CLVideoPlayerkText] as? String, highlighted: indexPath.row == highlightedIndex)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectSubtitleAtInterval(time: (transcriptArray[indexPath.row] as? [String: AnyObject])?[CLVideoPlayerkStart] as! TimeInterval)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTableDragged = true
        draggingTimer.invalidate()
        draggingTimer = Timer.scheduledTimer(timeInterval: dragDelay, target: self, selector: #selector(invalidateDragging), userInfo: nil, repeats: false)
    }
    
    func updateTranscript(transcript: [AnyObject]) {
        if transcript.count > 0 {
            transcriptArray = transcript
            transcriptTableView.reloadData()
            transcriptTableView.isHidden = false
        }
    }
    
    func highlightSubtitleForTime(time: TimeInterval?) {
        if let index = getTranscriptIndexForTime(time: time), index != highlightedIndex{
            highlightedIndex = index
            transcriptTableView.reloadData()
            if !isTableDragged {
                transcriptTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: UITableViewScrollPosition.middle, animated: true)
            }
        }
    }
    
    func getTranscriptIndexForTime(time: TimeInterval?) -> Int? {
        return transcriptArray.index(where: { time ?? 0 >= ($0 as? [String: AnyObject])?[CLVideoPlayerkStart] as? Double ?? 0 && time ?? 0 <= ($0 as? [String: AnyObject])?[CLVideoPlayerkEnd] as? Double ?? 0 })
    }
    
    func invalidateDragging(){
        isTableDragged = false
    }
}
