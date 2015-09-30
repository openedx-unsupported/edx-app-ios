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
}

// TODO : Make a property indexPath for the table view cell and then make a delegate which takes the TouchUpInside event as "downloadButtonPressed(indexPath : NSIndexPath)" method in the delegate.
private let titleLabelCenterYOffset = -12

class CourseVideoTableViewCell: UITableViewCell, CourseBlockContainerCell {
    
    static let identifier = "CourseVideoTableViewCellIdentifier"
    weak var delegate : CourseVideoTableViewCellDelegate?
    
    let content = CourseOutlineItemView(trailingImageIcon: Icon.ContentDownload)
    
    var block : CourseBlock? = nil {
        didSet {
            content.setTitleText(block?.name)
        }
    }
        
    var localState : OEXHelperVideoDownload? {
        didSet {
            updateIconForVideoState()
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
        
        content.addActionForTrailingIconTap {[weak self] _ in
            if let owner = self, block = owner.block {
                owner.delegate?.videoCellChoseDownload(owner, block : block)
            }
        }
        
        for notification in [OEXDownloadProgressChangedNotification, OEXDownloadEndedNotification] {
            NSNotificationCenter.defaultCenter().oex_addObserver(self, name: notification) { (_, observer, _) -> Void in
                observer.updateIconForVideoState()
            }
        }
    }
    
    func updateIconForVideoState() {
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
        
        content.setTrailingIconHidden(localState?.state != .New || (localState?.isVideoDownloading ?? false))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
