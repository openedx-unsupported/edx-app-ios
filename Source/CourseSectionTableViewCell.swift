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
    func reloadCell(cell: UITableViewCell)
}

class CourseSectionTableViewCell: SwipeableCell, CourseBlockContainerCell {
    
    static let identifier = "CourseSectionTableViewCellIdentifier"
    
    fileprivate let content = CourseOutlineItemView()
    fileprivate let videosStream = BackedStream<[OEXHelperVideoDownload]>()
    fileprivate let downloadView = DownloadsAccessoryView()
    weak var delegate : CourseSectionTableViewCellDelegate?
    fileprivate var spinnerTimer = Timer()
    var courseID: String?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }

        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, let block = owner.block, let videos = self?.videosStream.value {
                owner.delegate?.sectionCellChoseDownload(cell: owner, videos: videos, forBlock: block)
            }
        }
        videosStream.listen(self) {[weak self] downloads in
            if let downloads = downloads.value, let state = self?.downloadStateForDownloads(videos: downloads) {
                self?.downloadView.state = state
                self?.content.trailingView = self?.downloadView
                self?.downloadView.itemCount = downloads.count
            }
            else {
                self?.content.trailingView = nil
            }
        }
        
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXVideoStateChanged] {
            NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (_, observer, _) -> Void in
                if let state = observer.downloadStateForDownloads(videos: observer.videosStream.value) {
                    observer.downloadView.state = state
                }
                else {
                    observer.content.trailingView = nil
                }
            }
        }
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self, owner.downloadView.state == .Downloading {
                owner.delegate?.sectionCellChoseShowDownloads(cell: owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
    }
    
    var videos : OEXStream<[OEXHelperVideoDownload]> = OEXStream() {
        didSet {
            videosStream.backWithStream(videos)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videosStream.backWithStream(OEXStream(value:[]))
        reset()
    }
    
    func downloadStateForDownloads(videos : [OEXHelperVideoDownload]?) -> DownloadsAccessoryView.State? {
        guard let videos = videos, videos.count > 0 else { return nil }
        
        let allCompleted = videos.reduce(true) {(acc, video) in
            return acc && video.downloadState == .complete
        }
        
        if allCompleted {
            return .Done
        }
        
        let filteredVideos = filterVideos(videos: videos)
        
        let allDownloading = filteredVideos.reduce(true) {(acc, video) in
            return acc && video.downloadState == .partial
        }
        
        if allDownloading {
            return .Downloading
        }
        else {
            return .Available
        }
    }
    
    private func filterVideos(videos: [OEXHelperVideoDownload])-> [OEXHelperVideoDownload]{
        var incompleteVideos:[OEXHelperVideoDownload]  = []
        for video in videos {
            // only return incomplete videos
            if video.downloadState != .complete {
                incompleteVideos.append(video)
            }
        }
        
        return incompleteVideos
    }
    
    
    public func deleteVideos(videos : [OEXHelperVideoDownload]) {
        OEXInterface.shared().deleteDownloadedVideos(videos) { _ in }
        OEXAnalytics.shared().trackSubsectionDeleteVideos(courseID: courseID ?? "", subsectionID: block?.blockID ?? "")
    }
    
    public func areAllVideosDownloaded(videos: [OEXHelperVideoDownload]) -> Bool {
        
        let videosState = downloadStateForDownloads(videos: videos)
        return (videosState == .Done)
    }

    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(title: block?.displayName)
            content.isGraded = block?.graded
            content.setDetailText(title: block?.format ?? "")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CourseSectionTableViewCell: SwipeableCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeActionButton]? {
        
        var downloadVideos:[OEXHelperVideoDownload] = []
        videosStream.listen(self) { downloads in
            if let videos = downloads.value {
                downloadVideos = videos
            }
        }
        
        if(!areAllVideosDownloaded(videos: downloadVideos)) {
            return nil
        }
        let deleteButton = SwipeActionButton(title: nil, image: Icon.DeleteIcon.imageWithFontSize(size: 20)) {[weak self] action, indexPath in
            if let owner = self {
                //Showing a spinner while deleting video
                owner.deleteVideos(videos: downloadVideos)
                owner.downloadView.state = .Deleting
                owner.spinnerTimer = Timer.scheduledTimer(timeInterval: 0.4, target:owner, selector: #selector(owner.invalidateTimer), userInfo: nil, repeats: true)
            }
        }
        return [deleteButton]
    }
    
    @objc private func invalidateTimer(){
        spinnerTimer.invalidate()
        downloadView.state = .Done
        delegate?.reloadCell(cell: self)
    }
}

extension CourseSectionTableViewCell {
    public func t_setup() -> OEXStream<[OEXHelperVideoDownload]> {
        return videos
    }
    
    public func t_areAllVideosDownloaded(videos: [OEXHelperVideoDownload]) -> Bool {
        return areAllVideosDownloaded(videos: videos)
    }
}
