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
}

private let titleLabelCenterYOffset = -12

class CourseVideoTableViewCell: UITableViewCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    weak var delegate : CourseVideoTableViewCellDelegate?
    
    private let content = CourseOutlineItemView()
    private let downloadView = DownloadsAccessoryView()
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name)
        }
    }
        
    var localState : OEXHelperVideoDownload? {
        didSet {
            updateDownloadViewForVideoState()
            content.setDetailText(OEXDateFormatting.formatSecondsAsVideoLength(localState?.summary.duration ?? 0))
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(content)
        content.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView)
        }
        content.setContentIcon(Icon.CourseVideoContent)
        
        downloadView.downloadAction = {[weak self] _ in
            if let owner = self, block = owner.block {
                owner.delegate?.videoCellChoseDownload(owner, block : block)
            }
        }
        
        for notification in [OEXDownloadProgressChangedNotification, OEXDownloadEndedNotification, OEXVideoStateChangedNotification] {
            NSNotificationCenter.defaultCenter().oex_addObserver(self, name: notification) { (_, observer, _) -> Void in
                observer.updateDownloadViewForVideoState()
            }
        }
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self]_ in
            if let owner = self where owner.downloadState == .Downloading {
                owner.delegate?.videoCellChoseShowDownloads(owner)
            }
        }
        downloadView.addGestureRecognizer(tapGesture)
        
        content.trailingView = downloadView
        downloadView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
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
        switch localState?.watchedState ?? .Unwatched {
        case .Unwatched:
            content.leadingIconColor = OEXStyles.sharedStyles().primaryBaseColor()
            content.backgroundColor = UIColor.whiteColor()
        case .PartiallyWatched:
            content.leadingIconColor = OEXStyles.sharedStyles().primaryBaseColor()
            content.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        case .Watched:
            content.leadingIconColor = OEXStyles.sharedStyles().neutralDark()
            content.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        }
        
        downloadView.state = downloadState
    }
}
