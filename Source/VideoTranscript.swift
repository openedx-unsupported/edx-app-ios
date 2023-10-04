//
//  VideoTranscript.swift
//  edX
//
//  Created by Danial Zahid on 12/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit

protocol VideoTranscriptDelegate: AnyObject {
    func didSelectSubtitleAtInterval(time: TimeInterval)
}

class VideoTranscript: NSObject, UITableViewDelegate, UITableViewDataSource, ScrollableDelegateProvider {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider
    
    weak var scrollableDelegate: ScrollableDelegate?
    private var scrollByDragging = false
    
    let transcriptTableView = UITableView(frame: CGRect.zero, style: .plain)
    var transcripts = [TranscriptObject]()
    
    let environment : Environment
    weak var delegate : VideoTranscriptDelegate?
    
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
    }
    
    private func setupTable(tableView: UITableView) {
        tableView.register(VideoTranscriptTableViewCell.self, forCellReuseIdentifier: VideoTranscriptTableViewCell.cellIdentifier)
        tableView.separatorColor = UIColor.clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    //MARK: - UITableview methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcripts.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoTranscriptTableViewCell.cellIdentifier) as! VideoTranscriptTableViewCell
        cell.applyStandardSeparatorInsets()
        cell.setTranscriptText(text: transcripts[indexPath.row].text.decodingHTMLEntities, highlighted: indexPath.row == highlightedIndex)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectSubtitleAtInterval(time: transcripts[indexPath.row].start)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollByDragging {
            scrollableDelegate?.scrollViewDidScroll(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollByDragging = false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollByDragging = true
        isTableDragged = true
        draggingTimer.invalidate()
        draggingTimer = Timer.scheduledTimer(timeInterval: dragDelay, target: self, selector: #selector(invalidateDragging), userInfo: nil, repeats: false)
    }
    
    func updateTranscript(transcript: [TranscriptObject]) {
        if transcript.count > 0 {
            transcripts = transcript
            transcriptTableView.reloadData()
            transcriptTableView.isHidden = false
        }
    }
    
    func highlightSubtitle(for time: TimeInterval?) {
        if let index = getTranscriptIndex(for: time), index != highlightedIndex{
            highlightedIndex = index
            transcriptTableView.reloadData()
            if !isTableDragged {
                transcriptTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
            }
        }
    }
    
    func getTranscriptIndex(for time: TimeInterval?) -> Int? {
        guard let time = time else {
            return nil
        }
        return transcripts.firstIndex(where: { time >= $0.start && time <= $0.end })
    }
    
    @objc func invalidateDragging(){
        isTableDragged = false
    }
    
    deinit {
        draggingTimer.invalidate()
    }
}
