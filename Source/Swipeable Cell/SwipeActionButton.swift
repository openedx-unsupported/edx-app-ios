//
//  SwipeActionButton.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class SwipeActionButton: UIButton {
    private var maximumImageHeight: CGFloat = 0
    private var title: String?
    public var image: UIImage?
    public var handler: ((SwipeActionButton, IndexPath) -> Void)?
    
    private var currentSpacing: CGFloat {
        return (currentTitle?.isEmpty == false && maximumImageHeight > 0) ? StandardVerticalMargin : 0
    }
    
    private var alignmentRect: CGRect {
        let contentRect = self.contentRect(forBounds: bounds)
        let titleHeight = titleBoundingRect(with: contentRect.size).height
        let totalHeight = maximumImageHeight + titleHeight + currentSpacing
        
        return contentRect.center(size: CGSize(width: contentRect.width, height: totalHeight))
    }
    
    convenience init(title: String?, image: UIImage?, handler: ((SwipeActionButton, IndexPath) -> Void)?) {
        self.init(frame: .zero)
        self.title = title
        self.handler = handler
        self.image = image
        contentHorizontalAlignment = .center
        
        tintColor = OEXStyles.shared().neutralWhiteT()
        titleLabel?.font = OEXStyles.shared().semiBoldSansSerif(ofSize: 15)
        titleLabel?.textAlignment = .center
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        
        setTitle(title, for: .normal)
        setTitleColor(tintColor, for: .normal)
        setImage(image, for: .normal)
    }
    
    func setMaximumImageHeight(maxImageHeight: CGFloat) {
        maximumImageHeight = maxImageHeight
    }
    
    func preferredWidth(maximum: CGFloat) -> CGFloat {
        let width = maximum > 0 ? maximum : CGFloat.greatestFiniteMagnitude
        let textWidth = titleBoundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).width
        let imageWidth = currentImage?.size.width ?? 0
        
        return min(width, max(textWidth, imageWidth) + contentEdgeInsets.left + contentEdgeInsets.right)
    }
    
    func titleBoundingRect(with size: CGSize) -> CGRect {
        guard let title = currentTitle else { return .zero }
        
        return title.boundingRect(with: size, options: [.usesLineFragmentOrigin], attributes: [NSFontAttributeName: OEXStyles.shared().semiBoldSansSerif(ofSize: 15)], context: nil)
    }
    
    override public func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = contentRect.center(size: titleBoundingRect(with: contentRect.size).size)
        rect.origin.y = alignmentRect.minY + maximumImageHeight + currentSpacing
        return rect
    }
    
    override public func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = contentRect.center(size: currentImage?.size ?? .zero)
        rect.origin.y = alignmentRect.minY + (maximumImageHeight - rect.height) / 2
        return rect
    }
}

extension CGRect {
    func center(size: CGSize) -> CGRect {
        let dx = width - size.width
        let dy = height - size.height
        return CGRect(x: origin.x + dx * 0.5, y: origin.y + dy * 0.5, width: size.width, height: size.height)
    }
}
