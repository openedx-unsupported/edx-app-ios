//
//  ContentInsetsController.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol ContentInsetsSourceDelegate : class {
    func contentInsetsSourceChanged(source : ContentInsetsSource)
}

protocol ContentInsetsSource {
    var currentInsets : UIEdgeInsets { get }
    weak var insetsDelegate : ContentInsetsSourceDelegate? { get set }
    var affectsScrollIndicators : Bool { get }
}

/// General solution to the problem of edge insets that can change and need to
/// match a scroll view. When we drop iOS 7 support there may be a way to simplify this
/// by using the new layout margins API.
///
/// Other things like pull to refresh can be supported by creating a class that implements `ContentInsetsSource`
/// and providing a way to add it to the `insetsSources` list.
///
/// To use:
///  #. Call `setupInController:scrollView:` in the `viewDidLoad` method of your controller
///  #. Call `updateInsets` in the `viewDidLayoutSubviews` method of your controller
class ContentInsetsController: NSObject, ContentInsetsSourceDelegate {
    
    private var scrollView : UIScrollView?
    private weak var owner : UIViewController?
    
    private var insetSources : [ContentInsetsSource] = []
    
    var offlineController : OfflineModeController?
    
    func setupInController(owner : UIViewController, scrollView : UIScrollView) {
        self.owner = owner
        self.scrollView = scrollView
    }
    
    func supportOfflineMode(#styles : OEXStyles) {
        let offlineController = OfflineModeController(styles: styles)
        offlineController.insetsDelegate = self
        insetSources.append(offlineController)
        
        self.owner.map {
            offlineController.setupInController($0)
        }
        self.offlineController = offlineController
    }
    
    func supportDownloadsProgress(#interface : OEXInterface?, styles : OEXStyles) {
        let environment = DownloadProgressViewController.Environment(interface: interface, styles: styles)
        let controller = DownloadProgressViewController(environment: environment)
        controller.insetsDelegate = self
        insetSources.append(controller)
        self.owner.map {
            controller.setupInController($0)
        }
    }
    
    private var controllerInsets : UIEdgeInsets {
        let topGuideHeight = self.owner?.topLayoutGuide.length ?? 0
        let bottomGuideHeight = self.owner?.bottomLayoutGuide.length ?? 0
        return UIEdgeInsets(top : topGuideHeight, left : 0, bottom : bottomGuideHeight, right : 0)
    }
    
    func contentInsetsSourceChanged(source: ContentInsetsSource) {
        updateInsets()
    }
    
    func addSource(source : ContentInsetsSource) {
        insetSources.append(source)
        updateInsets()
    }
    
    func updateInsets() {
        let regularInsets = reduce(insetSources.map { $0.currentInsets }, controllerInsets, +)
        self.scrollView?.contentInset = regularInsets
        
        let indicatorSources = insetSources.filter { $0.affectsScrollIndicators }.map { $0.currentInsets }
        let indicatorInsets = reduce( indicatorSources, controllerInsets, +)
        self.scrollView?.scrollIndicatorInsets = indicatorInsets
    }
}
