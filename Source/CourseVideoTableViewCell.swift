//
//  CourseVideoTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 12/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


protocol CourseVideoTableViewCellDelegate : class {
    func videoCellChoseDownload(cell : CourseVideoTableViewCell, block : CourseBlock)
    func videoCellChoseShowDownloads(cell : CourseVideoTableViewCell)
    func reloadCell(cell: UITableViewCell)
}

private let titleLabelCenterYOffset = -12

class CourseVideoTableViewCell: SwipeableCell, CourseBlockContainerCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    weak var delegate : CourseVideoTableViewCellDelegate?
    
    private let content = CourseOutlineItemView()
    fileprivate let downloadView = DownloadsAccessoryView()
    fileprivate var spinnerTimer = Timer()
    var courseID: String?
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(title: block?.displayName)
            if let video = block?.type.asVideo {
                video.isDownloadableVideo ? (downloadView.isHidden = false) : (downloadView.isHidden = true)
            }
        }
    }
    
    var localState : OEXHelperVideoDownload? {
        didSet {
            updateDownloadViewForVideoState()
            
            guard let hasVideoDuration = localState?.summary?.hasVideoDuration, let hasVideoSize = localState?.summary?.hasVideoSize else {
                return
            }
            
            if (hasVideoDuration && hasVideoSize) {
                content.setDetailText(title: DateFormatting.formatSeconds(asVideoLength: localState?.summary?.duration ?? 0), blockType: block?.type, videoSize: localState?.summary?.videoSize())
            }
            else if(hasVideoDuration) {
                content.setDetailText(title: DateFormatting.formatSeconds(asVideoLength: localState?.summary?.duration ?? 0), blockType: block?.type)
            }
            else if(hasVideoSize)
            {
                content.setDetailText(title: localState?.summary?.videoSize() ?? "", blockType: block?.type)
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        content.setContentIcon(icon: Icon.CourseVideoContent)
        
        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, let block = owner.block {
                owner.delegate?.videoCellChoseDownload(cell: owner, block : block)
            }
        }
        
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXVideoStateChanged] {
            NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (_, observer, _) -> Void in
                observer.updateDownloadViewForVideoState()
            }
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self, owner.downloadState == .Downloading {
                owner.delegate?.videoCellChoseShowDownloads(cell: owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
        
        content.trailingView = downloadView
        downloadView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var downloadState : DownloadsAccessoryView.State {
        switch localState?.downloadProgress ?? 0 {
        case 0:
            return .Available
        case OEXMaxDownloadProgress:
            return .Done
        default:
            return .Downloading
        }
    }
    
    private func updateDownloadViewForVideoState() {
        switch localState?.watchedState ?? .unwatched {
        case .unwatched, .partiallyWatched:
            content.leadingIconColor = OEXStyles.shared().primaryBaseColor()
        case .watched:
            content.leadingIconColor = OEXStyles.shared().neutralDark()
        }
        
        guard !(self.localState?.summary?.onlyOnWeb ?? false) else {
            content.trailingView = nil
            return
        }
        
        content.trailingView = downloadView
        downloadView.state = downloadState
    }
    
   fileprivate func isVideoDownloaded() -> Bool{
        return (localState?.downloadState == OEXDownloadState.complete)
    }
    
   fileprivate func deleteVideo()  {
        if let video = localState {
            OEXInterface.shared().deleteDownloadedVideo(video, shouldNotify: true) { _ in }
            OEXAnalytics.shared().trackUnitDeleteVideo(courseID: courseID ?? "", unitID: block?.blockID ?? "")
        }
    }
}

extension CourseVideoTableViewCell: SwipeableCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeActionButton]? {
        
        if(!isVideoDownloaded()) {
            return nil
        }
        
        let deleteButton = SwipeActionButton(title: nil, image: Icon.DeleteIcon.imageWithFontSize(size: 20)) {[weak self] action, indexPath in
        //Showing a spinner while deleting video
            if let owner = self {
                owner.deleteVideo()
                owner.downloadView.state = .Deleting
                owner.spinnerTimer = Timer.scheduledTimer(timeInterval: 0.4, target:owner, selector: #selector(owner.invalidateTimer), userInfo: nil, repeats: true)
            }
            tableView.hideSwipeCell()
        }
        return [deleteButton]
    }

    @objc private func invalidateTimer(){
        spinnerTimer.invalidate()
        downloadView.state = .Done
        delegate?.reloadCell(cell: self)
    }
}
