//
//  JSONFormBuilderTextEditor.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class JSONFormBuilderTextEditorViewController: UIViewController {
    private let containerView = UIScrollView()
    private let insetsController = ContentInsetsController()
    
    let textView = OEXPlaceholderTextView()
    var text: String { return textView.text }
    
    var doneEditing: ((value: String)->())?
    
    init(text: String?, placeholder: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.view = UIView()
        self.view.backgroundColor = UIColor.whiteColor()
        
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        textView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        textView.placeholderTextColor = OEXStyles.sharedStyles().neutralBase()
        textView.textColor = OEXStyles.sharedStyles().neutralBlackT()

        
        textView.text = text ?? ""
        if let placeholder = placeholder {
            textView.placeholder = placeholder
        }
        textView.delegate = self
        
        setupViews()
        addOfflineSupport()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OEXAnalytics.sharedAnalytics().trackScreenWithName(OEXAnalyticsScreenEditTextFormValue)
    }
    
    private func addOfflineSupport() {
        insetsController.setupInController(self, scrollView: containerView)
        insetsController.supportOfflineMode(OEXRouter.sharedRouter().environment.reachability)
    }

    private func setupViews() {
        view.addSubview(containerView)
        containerView.addSubview(textView)
        
        containerView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        textView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(containerView.snp_topMargin).offset(15)
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