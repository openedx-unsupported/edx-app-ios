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
    private let downloadView = DownloadsAccessoryView()
    private var spinnerTimer = Timer()
    
    var courseOutlineMode: CourseOutlineMode = .full
    
    var courseID: String?
    
    var isSectionOutline = false {
        didSet {
            content.isSectionOutline = isSectionOutline
        }
    }
    
    var block : CourseBlock? = nil {
        didSet {
            guard let block = block else { return }
            
            content.setTitleText(title: block.displayName)
            
            if block.isCompleted && !block.isGated {
                content.backgroundColor = OEXStyles.shared().successXXLight()
                content.setContentIcon(icon: Icon.CheckCircle, color: OEXStyles.shared().successBase())
                content.setSeperatorColor(color: OEXStyles.shared().successXLight())
            } else if block.isGated {
                content.leadingIconColor = OEXStyles.shared().neutralXLight()
                content.setContentIcon(icon: nil, color: .clear)
                content.setSeperatorColor(color: OEXStyles.shared().neutralXLight())
            } else {
                content.backgroundColor = OEXStyles.shared().neutralWhite()
                content.setContentIcon(icon: nil, color: .clear)
                content.setSeperatorColor(color: OEXStyles.shared().neutralXLight())
            }
            
            if let video = block.type.asVideo {
                downloadView.isHidden = !video.isDownloadableVideo
            }
        }
    }
    
    var localState : OEXHelperVideoDownload? {
        didSet {
            updateDownloadViewForVideoState()
            
            guard let hasVideoDuration = localState?.summary?.hasVideoDuration,
                  let duration = localState?.summary?.duration else {
                return
            }
            
            if hasVideoDuration {
                content.shouldShowCheckmark = false
                content.setDetailText(title: formattedDetailText(with: duration), blockType: block?.type)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        content.setTitleTrailingIcon(icon: Icon.CourseVideoContent)
        
        downloadView.downloadAction = {[weak self] in
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
        downloadView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseVideoTableViewCell:view"
        content.accessibilityIdentifier = "CourseVideoTableViewCell:content-view"
        downloadView.accessibilityIdentifier = "CourseVideoTableViewCell:download-view"
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
            content.leadingIconColor = OEXStyles.shared().neutralXDark()
        @unknown default:
            break
        }
        
        guard !(self.localState?.summary?.onlyOnWeb ?? false) else {
            content.hideTrailingView()
            return
        }
        
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
    
    private func formattedDetailText(with duration: Double) -> String {
        let (hours, mins) = DateFormatting.formatVideoDuration(totalSeconds: duration)
        
        var detailText = ""
        
        if hours == 0 {
            detailText = Strings.courseVideoMinutes(minutes: mins)
        } else {
            if mins == 0 {
                detailText = Strings.courseVideoHours(hours: hours)
            } else if hours > 1 && mins > 1 {
                detailText = "\(Strings.courseVideoHours(hours: hours)), \(Strings.courseVideoMinutes(minutes: mins))"
            }
        }
        
        return detailText
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
