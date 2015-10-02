//
//  CourseSectionTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 04/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseSectionTableViewCellDelegate : class {
    func sectionCellChoseDownload(cell : CourseSectionTableViewCell, videos : [OEXHelperVideoDownload], forBlock block : CourseBlock)
    func sectionCellChoseShowDownloads(cell : CourseSectionTableViewCell)
}

class CourseSectionTableViewCell: UITableViewCell, CourseBlockContainerCell {
    
    static let identifier = "CourseSectionTableViewCellIdentifier"
    
    private let content = CourseOutlineItemView()
    private let downloadView = DownloadsAccessoryView()

    weak var delegate : CourseSectionTableViewCellDelegate?
    
    private var videosStream = BackedStream<[OEXHelperVideoDownload]>()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }

        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, block = owner.block, videos = self?.videosStream.value {
                owner.delegate?.sectionCellChoseDownload(owner, videos: videos, forBlock: block)
            }
        }
        videosStream.listen(self) {[weak self] downloads in
            if let downloads = downloads.value, state = self?.downloadStateForDownloads(downloads) {
                self?.downloadView.state = state
                self?.content.trailingView = self?.downloadView
                self?.downloadView.itemCount = downloads.count
            }
            else {
                self?.content.trailingView = nil
            }
        }
        
        for notification in [OEXDownloadProgressChangedNotification, OEXDownloadEndedNotification, OEXVideoStateChangedNotification] {
            NSNotificationCenter.defaultCenter().oex_addObserver(self, name: notification) { (_, observer, _) -> Void in
                if let state = observer.downloadStateForDownloads(observer.videosStream.value) {
                    observer.downloadView.state = state
                }
                else {
                    observer.content.trailingView = nil
                }
            }
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self where owner.downloadView.state == .Downloading {
                owner.delegate?.sectionCellChoseShowDownloads(owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
    }
    
    var videos : Stream<[OEXHelperVideoDownload]> = Stream() {
        didSet {
            videosStream.backWithStream(videos)
        }
    }
    
    override func prepareForReuse() {
        videosStream = BackedStream<[OEXHelperVideoDownload]>()
    }
    
    func downloadStateForDownloads(videos : [OEXHelperVideoDownload]?) -> DownloadsAccessoryView.State? {
        if let videos = videos where videos.count > 0 {
            let allDownloading = videos.reduce(true) {(acc, video) in
                return acc && video.downloadState == .Partial
            }
            
            let allCompleted = videos.reduce(true) {(acc, video) in
                return acc && video.downloadState == .Complete
            }
            
            if allDownloading {
                return .Downloading
            }
            else if allCompleted {
                return .Done
            }
            else {
                return .Available
            }
        }
        else {
            return nil
        }
    }
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name)
            content.isGraded = block?.graded
            content.setDetailText(block?.format ?? "")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
