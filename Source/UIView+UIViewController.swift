//
//  UIView+UIViewController.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension UIView {
    func firstAvailableUIViewController() -> UIViewController? {
        return traverseResponderChainForUIViewController()
    }
    
    private func traverseResponderChainForUIViewController() -> UIViewController? {
        let nextResponder = self.next
        if let nextResponder = nextResponder {
            if nextResponder is UIViewController {
                return nextResponder as? UIViewController
            }
            else if nextResponder is UIView {
                let view = nextResponder as? UIView
                return view?.traverseResponderChainForUIViewController()
            }
        }
        
        return nil
    }
    
    func handleDynamicTypeNotification() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIContentSizeCategoryDidChange.rawValue) { (_, observer, _) in
                observer.updateFontsOfSubviews(view: observer)
                observer.layoutIfNeeded()
            
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE)))
        }
    }
    
    private func updateFontsOfSubviews(view: UIView) {
        if (view.superview is UITabBar) {
            return
        }
        let subviews = view.subviews
        guard subviews.count > 0 else {
            return
        }
        
        for subview in subviews {
            if let view = subview as? UILabel, let font = view.font.preferredFont() {
                view.font = font
            }
            else if let view = subview as? UITextField, let font = view.font?.preferredFont() {
                view.font = font
            }
            else if let view = subview as? UITextView, let font = view.font?.preferredFont() {
                    view.font = font
            }
            else if let view = subview as? UIButton {
                if let style = view.titleLabel?.font.styleAttribute() {
                    if let attributeText = view.titleLabel?.attributedText, attributeText.length > 0 {
                        let attributes = attributeText.attributes(at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, attributeText.length))
                        let mutableAtrributedText = NSMutableAttributedString(string: view.titleLabel?.text ?? "" , attributes: attributes)
                        mutableAtrributedText.addAttribute(NSFontAttributeName, value: UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style)), range: NSMakeRange(0, mutableAtrributedText.length))
                        view.setAttributedTitle(mutableAtrributedText, for: .normal)
                    }
                }
            }
            else if let view = subview as? UISegmentedControl {
                let font =  UIFont().preferredFont(with: .subheadline)
                view.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
            }
            else {
                updateFontsOfSubviews(view: subview)
            }
        }
    }
}
