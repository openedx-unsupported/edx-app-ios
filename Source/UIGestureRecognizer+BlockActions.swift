//
//  UIGestureRecognizer+BlockActions.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private class GestureListener : Removable {
    let token = malloc(1)
    var action : ((UIGestureRecognizer) -> Void)?
    var removeAction : ((GestureListener) -> Void)?
    
    deinit {
        free(token)
    }
    
    @objc func gestureFired(gesture : UIGestureRecognizer) {
        self.action?(gesture)
    }
    
    func remove() {
        removeAction?(self)
    }
}

protocol GestureActionable {
    init(target : AnyObject?, action : Selector)
}

extension UIGestureRecognizer : GestureActionable {}

extension GestureActionable where Self : UIGestureRecognizer {
    
    init(action : @escaping (Self) -> Void) {
        self.init(target: nil, action: nil)
        addAction(action: action)
    }
    
    init(target : AnyObject?, action : Selector) {
        self.init(target: nil, action: nil)
    }
    
    @discardableResult func addAction(action : @escaping (Self) -> Void) -> Removable {
        let listener = GestureListener()
        listener.action = {(gesture : UIGestureRecognizer) in
            if let gesture = gesture as? Self {
                action(gesture)
            }
        }
        objc_setAssociatedObject(self, listener.token ?? malloc(1), listener, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        listener.removeAction = {[weak self] (listener : GestureListener) in
            self?.removeTarget(listener, action: nil)
            if let owner = self {
                objc_setAssociatedObject(owner, listener.token ?? malloc(1), nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }

        }
        self.addTarget(listener, action: #selector(GestureListener.gestureFired(gesture :)))
        
        return listener
    }
}

class AttachmentTapGestureRecognizer: UITapGestureRecognizer {

    typealias TappedAttachment = (attachment: NSTextAttachment, characterIndex: Int)
    private var action: ((AttachmentTapGestureRecognizer) -> Void)?
    
    init(action: @escaping (AttachmentTapGestureRecognizer) -> Void) {
        super.init(target: nil, action: nil)
        self.action = action
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let textView = view as? UITextView else {
            state = .failed
            return
        }

        if let touch = touches.first, let _ = evaluateTouch(touch, on: textView) {
            super.touchesBegan(touches, with: event)
            action?(self)
        } else {
            state = .failed
        }
    }

    private func evaluateTouch(_ touch: UITouch, on textView: UITextView) -> TappedAttachment? {
        let touch = touch.location(in: textView)
        let point = CGPoint(x: touch.x - textView.textContainerInset.left, y: touch.y - textView.textContainerInset.top)
        let glyphIndex: Int = textView.layoutManager.glyphIndex(for: point, in: textView.textContainer, fractionOfDistanceThroughGlyph: nil)
        let glyphRect = textView.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textView.textContainer)
        guard glyphRect.contains(point) else { return nil }
        let characterIndex = textView.layoutManager.characterIndexForGlyph(at: glyphIndex)
        guard characterIndex < textView.textStorage.length, NSTextAttachment.character == (textView.textStorage.string as NSString).character(at: characterIndex), let attachment = textView.textStorage.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment else { return nil }
        return (attachment, characterIndex)
    }
}
