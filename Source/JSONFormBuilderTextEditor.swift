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
    
    var doneEditing: ((_ value: String)->())?
    
    init(text: String?, placeholder: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.view = UIView()
        self.view.backgroundColor = UIColor.white
        
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = OEXStyles.shared().standardTextViewInsets
        textView.typingAttributes = OEXStyles.shared().textAreaBodyStyle.attributes
        textView.placeholderTextColor = OEXStyles.shared().neutralBase()
        textView.textColor = OEXStyles.shared().neutralBlackT()

        textView.placeholder = placeholder ?? ""
        textView.text = text ?? ""
        textView.delegate = self
        
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OEXAnalytics.shared().trackScreen(withName: OEXAnalyticsScreenEditTextFormValue)
    }

    private func setupViews() {
        view.addSubview(textView)
        
        textView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_topMargin).offset(15)
            make.leading.equalTo(view.snp_leadingMargin)
            make.trailing.equalTo(view.snp_trailingMargin)
            make.bottom.equalTo(view.snp_bottomMargin)
        }
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil { //removing from the hierarchy
            doneEditing?(textView.text)
        }
    }
}

extension JSONFormBuilderTextEditorViewController : UITextViewDelegate {
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
}
