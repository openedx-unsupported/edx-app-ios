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
        
        self.view = UIView()
        self.view.backgroundColor = UIColor.whiteColor()
        
        textView.text = text ?? ""
        if let placeholder = placeholder {
            textView.placeholder = placeholder
        }
        textView.delegate = self
        
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        view.addSubview(textView)
        
        textView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_topMargin)
            make.leading.equalTo(view.snp_leadingMargin)
            make.trailing.equalTo(view.snp_trailingMargin)
            make.bottom.equalTo(view.snp_bottomMargin)
        }
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