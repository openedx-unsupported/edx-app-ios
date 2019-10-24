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
        NotificationCenter.default.oex_addObserver(observer: self, name: UIContentSizeCategory.didChangeNotification.rawValue) { (_, observer, _) in
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
            if let label = subview as? UILabel, let font = label.font.preferredFont {
                label.font = font
            }
            else if let textField = subview as? UITextField, let font = textField.font?.preferredFont {
                textField.font = font
            }
            else if let textView = subview as? UITextView, let font = textView.font?.preferredFont {
                    textView.font = font
            }
            else if let button = subview as? UIButton {
                if let style = button.titleLabel?.font.styleAttribute {
                    if let attributeText = button.titleLabel?.attributedText, attributeText.length > 0 {
                        let attributes = attributeText.attributes(at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, attributeText.length))
                        let mutableAtrributedText = NSMutableAttributedString(string: button.titleLabel?.text ?? "" , attributes: attributes)
                        mutableAtrributedText.addAttribute(NSAttributedString.Key.font, value: UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style)), range: NSMakeRange(0, mutableAtrributedText.length))
                        button.setAttributedTitle(mutableAtrributedText, for: .normal)
                    }
                }
            }
            else if let segmentControl = subview as? UISegmentedControl {
                let font =  UIFont().preferredFont(with: .subheadline)
                segmentControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
            }
            else {
                updateFontsOfSubviews(view: subview)
            }
        }
    }
}
