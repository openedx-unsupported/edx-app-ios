//
//  JSONFormBuilderTextEditor.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class JSONFormBuilderTextEditorViewController: UIViewController {
    let textView = OEXPlaceholderTextView()
    var text: String { return textView.text }
    
    var doneEditing: ((value: String)->())?
    
    init(text: String?, placeholder: String?) {
        super.init(nibName: nil, bundle: nil)
        
        textView.text = text
        if let placeholder = placeholder {
            textView.placeholder = placeholder
        }
        textView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil { //removing from the hierarchy
            doneEditing?(value: textView.text)
        }
    }

    
}

extension JSONFormBuilderTextEditorViewController : UITextViewDelegate {
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
}