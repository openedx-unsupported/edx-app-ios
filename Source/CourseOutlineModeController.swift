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
    
    public var isVideo : Bool {
        switch self {
        case .Video:
            return true
        default:
            return false
        }
    }
}

public protocol CourseOutlineModeControllerDelegate : class {
    func viewControllerForCourseOutlineModeChange() -> UIViewController
    func courseOutlineModeChanged(courseMode : CourseOutlineMode)
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
        let button = UIButton(type: .System)
        self.barItem = UIBarButtonItem(customView: button)
        self.barItem.accessibilityLabel = Strings.courseModePickerDescription
        
        super.init()
        
        self.updateIconForButton(button)
        
        button.oex_addAction({[weak self] _ in
            self?.showModeChanger()
        }, forEvents: .TouchUpInside)
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: dataSource.modeChangedNotificationName) { (_, owner, _) -> Void in
            owner.updateIconForButton(button)
            owner.delegate?.courseOutlineModeChanged(owner.dataSource.currentOutlineMode)
        }
    }
    
    private func updateIconForButton(button : UIButton) {
        let icon : Icon
        let insets : UIEdgeInsets
        // The icon should show the *next* mode, not the current one
        switch dataSource.currentOutlineMode {
        case .Full:
            icon = Icon.CourseModeVideo
            insets = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        case .Video:
            icon = Icon.CourseModeFull
            insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        button.imageEdgeInsets = insets
        button.setImage(icon.barButtonImage(), forState: .Normal)
        button.sizeToFit()
        button.bounds = CGRectMake(0, 0, 20, button.bounds.size.height)
    }
    
    var currentMode : CourseOutlineMode {
        return dataSource.currentOutlineMode
    }
    
    func showModeChanger() {
        let items : [(title : String, value : CourseOutlineMode)] = [
            (title :Strings.courseModeFull, value : CourseOutlineMode.Full),
            (title : Strings.courseModeVideo, value : CourseOutlineMode.Video)
        ]
        
        let controller = UIAlertController.actionSheetWithItems(items, currentSelection: self.currentMode) {[weak self] mode in
            self?.dataSource.currentOutlineMode = mode
        }
        
        controller.addCancelAction()
        
        let presenter = delegate?.viewControllerForCourseOutlineModeChange()
        presenter?.presentViewController(controller, animated: true, completion: nil)
    }
}