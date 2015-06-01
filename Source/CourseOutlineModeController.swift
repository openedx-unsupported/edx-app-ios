//
//  CourseOutlineModeController.swift
//  edX
//
//  Created by Akiva Leffert on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public enum CourseOutlineMode : String {
    case Full = "full"
    case Video = "video"
}

public protocol CourseOutlineModeControllerDelegate : class {
    func viewControllerForCourseOutlineModeChange() -> UIViewController
    func courseOutlineModeChanged(courseMode : CourseOutlineMode)
}

private func currentIconWithDataSource(dataSource : CourseOutlineModeControllerDataSource) -> Icon {
    switch dataSource.currentOutlineMode {
    case .Full:
        return Icon.CourseModeFull
    case .Video:
        return Icon.CourseModeVideo
    }
}

public protocol CourseOutlineModeControllerDataSource : class {
    var currentOutlineMode : CourseOutlineMode { get set }
    var modeChangedNotificationName : String { get }
}

class CourseOutlineModeController : NSObject {
    
    let barItem : UIBarButtonItem
    private let dataSource : CourseOutlineModeControllerDataSource
    weak var delegate : CourseOutlineModeControllerDelegate?

    
    init(dataSource : CourseOutlineModeControllerDataSource) {
        self.dataSource = dataSource
        let icon = currentIconWithDataSource(dataSource)
        self.barItem = UIBarButtonItem(title: icon.textRepresentation, style: .Plain, target: nil, action: nil)
        
        super.init()
        
        self.barItem.setTitleTextAttributes([NSFontAttributeName : Icon.fontWithTitleSize()], forState: .Normal)
        
        self.barItem.oex_setAction {[weak self] _ in
            self?.showModeChanger()
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: dataSource.modeChangedNotificationName) { (_, owner, __ArrayType) -> Void in
            owner.barItem.title = currentIconWithDataSource(owner.dataSource).textRepresentation
            owner.delegate?.courseOutlineModeChanged(owner.dataSource.currentOutlineMode)
        }
    }
    
    var currentMode : CourseOutlineMode {
        return dataSource.currentOutlineMode
    }
    
    func showModeChanger() {
        let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("COURSE_FULL_MODE", nil)) {[weak self] _ in
            self?.dataSource.currentOutlineMode = .Full
        })
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("COURSE_VIDEO_MODE", nil)) {[weak self] _ in
            self?.dataSource.currentOutlineMode = .Video
        })
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel) { _ in
        })
 
        if let presenter = delegate?.viewControllerForCourseOutlineModeChange() {
            controller.showWithSender(nil, controller: presenter, animated: true, completion: nil)
        }
    }
}