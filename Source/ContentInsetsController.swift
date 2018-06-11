//
//  ContentInsetsController.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol ContentInsetsSourceDelegate : class {
    func contentInsetsSourceChanged(source : ContentInsetsSource)
}

public protocol ContentInsetsSource : class {
    var currentInsets: UIEdgeInsets { get }
    var insetsDelegate: ContentInsetsSourceDelegate? { get set }
    var affectsScrollIndicators: Bool { get }
}


public class ConstantInsetsSource : ContentInsetsSource {
    public var currentInsets : UIEdgeInsets {
        didSet {
            self.insetsDelegate?.contentInsetsSourceChanged(source: self)
        }
    }
    
    public let affectsScrollIndicators : Bool
    public weak var insetsDelegate : ContentInsetsSourceDelegate?

    public init(insets : UIEdgeInsets, affectsScrollIndicators : Bool) {
        self.currentInsets = insets
        self.affectsScrollIndicators = affectsScrollIndicators
    }
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
public class ContentInsetsController: NSObject, ContentInsetsSourceDelegate {
    
    private var scrollView : UIScrollView?
    private weak var owner : UIViewController?
    
    private var insetSources : [ContentInsetsSource] = []

    // Keyboard is separated out since it isn't a simple sum, but instead overrides other
    // insets when present
    private var keyboardSource : ContentInsetsSource?
    
    public func setupInController(owner : UIViewController, scrollView : UIScrollView) {
        self.owner = owner
        self.scrollView = scrollView
        keyboardSource = KeyboardInsetsSource(scrollView: scrollView)
        keyboardSource?.insetsDelegate = self
    }
    
    private var controllerInsets : UIEdgeInsets {
        let topGuideHeight = self.owner?.topLayoutGuide.length ?? 0
        let bottomGuideHeight = self.owner?.bottomLayoutGuide.length ?? 0
        return UIEdgeInsets(top : topGuideHeight, left : 0, bottom : bottomGuideHeight, right : 0)
    }
    
    public func contentInsetsSourceChanged(source: ContentInsetsSource) {
        updateInsets()
    }
    
    public func addSource(source : ContentInsetsSource) {
        source.insetsDelegate = self
        insetSources.append(source)
        updateInsets()
    }
    
    public func updateInsets() {
        var regularInsets = insetSources
            .map { $0.currentInsets }
            .reduce(controllerInsets, +)
        let indicatorSources = insetSources
            .filter { $0.affectsScrollIndicators }
            .map { $0.currentInsets }
        var indicatorInsets = indicatorSources.reduce(controllerInsets, +)
        
        if let keyboardHeight = keyboardSource?.currentInsets.bottom {
            regularInsets.bottom = max(keyboardHeight, regularInsets.bottom)
            indicatorInsets.bottom = max(keyboardHeight, indicatorInsets.bottom)
        }
        self.scrollView?.contentInset = regularInsets
        
        self.scrollView?.scrollIndicatorInsets = indicatorInsets
    }
}
