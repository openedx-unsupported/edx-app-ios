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
    
    func updateFontsOfSubviews(v: UIView) {
        if (v.superview is UITabBar) || (v.superview is UINavigationBar) {
            return
        } else {
            let subviews = v.subviews
            guard subviews.count > 0 else {
                return
            }
            
            for subview in subviews {
                if let view = subview as? UILabel {
                    if let style = view.font.fontDescriptor.object(forKey: UIFontDescriptorTextStyleAttribute) as? UIFontTextStyle {
                           view.font = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style))
                    }
                } else if let view = subview as? UITextField {
                    if let style = view.font?.fontDescriptor.object(forKey: UIFontDescriptorTextStyleAttribute) as? UIFontTextStyle {
                        view.font = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style))
                    }
                } else if let view = subview as? UITextView {
                    if let style = view.font?.fontDescriptor.object(forKey: UIFontDescriptorTextStyleAttribute) as? UIFontTextStyle {
                        view.font = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style))
                    }
                }  else if let view = subview as? UIButton {
                    if let style = view.titleLabel?.font.fontDescriptor.object(forKey: UIFontDescriptorTextStyleAttribute) as? UIFontTextStyle {
                        if let attributeText = view.titleLabel?.attributedText, attributeText.length > 0 {
                            let attributes = attributeText.attributes(at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, attributeText.length))
                            let mutableAtrributedText = NSMutableAttributedString(string: view.titleLabel?.text ?? "" , attributes: attributes)
                            mutableAtrributedText.addAttribute(NSFontAttributeName, value: UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: UIFont().preferredFontSize(textStyle: style)), range: NSMakeRange(0, mutableAtrributedText.length))
                            view.setAttributedTitle(mutableAtrributedText, for: .normal)
                        }
                    }
                } else if let view = subview as? UISegmentedControl {
                    let font =  UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline), size: UIFont().preferredFontSize(textStyle: .subheadline))
                    view.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
                }
                else {
                    updateFontsOfSubviews(v: subview)
                }
            }
        }
    }
}
